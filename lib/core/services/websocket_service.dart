import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'encryption_service.dart';
import 'api_service.dart';

DateTime _parseServerDateTimeToLocal(dynamic raw) {
  final rawText = raw?.toString().trim() ?? '';
  if (rawText.isEmpty) return DateTime.now();

  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawText);
  final normalized = hasZone ? rawText : '${rawText}Z';
  final parsed = DateTime.tryParse(normalized);
  return (parsed ?? DateTime.now()).toLocal();
}

/// WebSocket service for real-time encrypted messaging
class WebSocketService {
  // Spring endpoint exposed for chat websocket handshake.
  static const String wsBaseUrl = 'wss://ispilo.hantardev.tech/ws/chat';

  StompClient? _stompClient;
  final List<StompUnsubscribe> _unsubscribers = <StompUnsubscribe>[];
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;
  String? _authTokenForReconnect;

  static const Duration _heartbeatOutgoing = Duration(seconds: 10);
  static const Duration _heartbeatIncoming = Duration(seconds: 10);
  static const Duration _reconnectBaseDelay = Duration(seconds: 1);
  static const Duration _reconnectMaxDelay = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 8;
  late String _conversationId;
  late String _userId;
  late String _encryptionKey;
  late EncryptionService _encryptionService;

  final ValueNotifier<List<ChatMessage>> messageNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  final ValueNotifier<Map<String, bool>> typingNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>?> deliveryReceiptNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> reactionNotifier =
    ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, bool>> presenceNotifier = ValueNotifier({});
  static const int _maxDebugEvents = 200;
  static const String _wsDebugTag = '[WS-DEBUG]';
  static const String _wsDebugReportTag = '[WS-DEBUG-REPORT]';
  static DateTime? _lastTerminalReportAt;
  static final ValueNotifier<List<WebSocketDebugEvent>> debugEventsNotifier =
      ValueNotifier<List<WebSocketDebugEvent>>(<WebSocketDebugEvent>[]);

  bool get isConnected => isConnectedNotifier.value;

  static void clearDebugEvents() {
    debugEventsNotifier.value = <WebSocketDebugEvent>[];
  }

  static String buildDebugReport({
    String? conversationId,
    String? userId,
    String? notes,
  }) {
    final report = <String, dynamic>{
      'reportType': 'websocket_messaging_debug',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'conversationId': conversationId,
      'userId': userId,
      'notes': notes,
      'events': debugEventsNotifier.value.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(report);
  }

  static void printDebugReportToTerminal({
    String? conversationId,
    String? userId,
    String? notes,
    bool force = false,
    bool clearAfterPrint = false,
  }) {
    final now = DateTime.now().toUtc();
    final last = _lastTerminalReportAt;
    if (!force && last != null && now.difference(last).inSeconds < 6) {
      return;
    }
    _lastTerminalReportAt = now;

    final report = buildDebugReport(
      conversationId: conversationId,
      userId: userId,
      notes: notes,
    );

    debugPrint('$_wsDebugReportTag START');
    for (final line in report.split('\n')) {
      debugPrint('$_wsDebugReportTag $line');
    }
    debugPrint('$_wsDebugReportTag END');

    if (clearAfterPrint) {
      clearDebugEvents();
    }
  }

  static void _recordDebugEvent(WebSocketDebugEvent event) {
    final events = List<WebSocketDebugEvent>.from(debugEventsNotifier.value)
      ..add(event);
    if (events.length > _maxDebugEvents) {
      events.removeRange(0, events.length - _maxDebugEvents);
    }
    debugEventsNotifier.value = events;

    debugPrint(
      '$_wsDebugTag ${event.direction.toUpperCase()} '
      'action=${event.action} '
      'dest=${event.destination ?? '-'} '
      'conv=${event.conversationId ?? '-'} '
      'msgType=${event.messageType ?? '-'} '
      'clientMsgId=${event.clientMsgId ?? '-'} '
      'status=${event.status ?? '-'} '
      'details=${event.details ?? '-'}',
    );
  }

  /// Initialize WebSocket connection with authentication
  Future<void> initialize({
    required String conversationId,
    required String userId,
    required String encryptionKey,
    required String authToken,
    bool resetReconnectState = true,
  }) async {
    _conversationId = conversationId;
    _userId = userId;
    _encryptionKey = encryptionKey;
  _authTokenForReconnect = authToken;
    _encryptionService = EncryptionService();
    _manualDisconnect = false;
    if (resetReconnectState) {
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
    }

    try {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'system',
          action: 'connect_attempt',
          destination: wsBaseUrl,
          conversationId: conversationId,
          userId: userId,
        ),
      );

      _stompClient?.deactivate();
      _stompClient = StompClient(
        config: StompConfig(
          url: wsBaseUrl,
          heartbeatOutgoing: _heartbeatOutgoing,
          heartbeatIncoming: _heartbeatIncoming,
          stompConnectHeaders: {
            'Authorization': 'Bearer $authToken',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $authToken',
          },
          onConnect: (frame) {
            isConnectedNotifier.value = true;
            _reconnectAttempts = 0;
            _reconnectTimer?.cancel();

            _recordDebugEvent(
              WebSocketDebugEvent(
                direction: 'system',
                action: 'connect_success',
                destination: wsBaseUrl,
                conversationId: conversationId,
                userId: userId,
                status: frame.command,
              ),
            );

            _subscribeCoreTopics(conversationId);
            joinConversation(conversationId);
            print('STOMP connected to conversation: $conversationId');
          },
          onStompError: (frame) {
            _recordDebugEvent(
              WebSocketDebugEvent(
                direction: 'error',
                action: 'stomp_error',
                conversationId: _conversationId,
                userId: _userId,
                status: frame.command,
                details: frame.body,
              ),
            );
            printDebugReportToTerminal(
              conversationId: _conversationId,
              userId: _userId,
              notes: 'stomp_error',
              force: true,
            );
            isConnectedNotifier.value = false;
            _handleSocketFailure('stomp_error');
          },
          onWebSocketError: (dynamic error) {
            _recordDebugEvent(
              WebSocketDebugEvent(
                direction: 'error',
                action: 'websocket_error',
                conversationId: _conversationId,
                userId: _userId,
                status: 'error',
                details: error.toString(),
              ),
            );
            printDebugReportToTerminal(
              conversationId: _conversationId,
              userId: _userId,
              notes: 'websocket_error',
              force: true,
            );
            isConnectedNotifier.value = false;
            _handleSocketFailure('websocket_error');
          },
          onDisconnect: (_) {
            _recordDebugEvent(
              WebSocketDebugEvent(
                direction: 'system',
                action: 'socket_closed',
                conversationId: _conversationId,
                userId: _userId,
                status: 'disconnect',
              ),
            );
            isConnectedNotifier.value = false;
            if (!_manualDisconnect) {
              _handleSocketFailure('disconnect');
            }
          },
        ),
      );

      _stompClient?.activate();
    } catch (e) {
      isConnectedNotifier.value = false;
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'connect_failed',
          destination: wsBaseUrl,
          conversationId: conversationId,
          userId: userId,
          status: 'error',
          details: e.toString(),
        ),
      );
      printDebugReportToTerminal(
        conversationId: conversationId,
        userId: userId,
        notes: 'connect_failed',
        force: true,
      );
      print('WebSocket connection failed: $e');
      _handleSocketFailure('connect_failed');
      rethrow;
    }
  }

  void _handleSocketFailure(String reason) {
    if (_manualDisconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'system',
          action: 'reconnect_stopped',
          conversationId: _conversationId,
          userId: _userId,
          status: 'max_attempts',
          details: 'reason=$reason attempts=$_reconnectAttempts',
        ),
      );
      return;
    }

    if (_reconnectTimer?.isActive == true) {
      return;
    }

    final multiplier = 1 << _reconnectAttempts;
    final nextSeconds = _reconnectBaseDelay.inSeconds * multiplier;
    final delaySeconds = nextSeconds > _reconnectMaxDelay.inSeconds
        ? _reconnectMaxDelay.inSeconds
        : nextSeconds;
    final delay = Duration(seconds: delaySeconds);

    _recordDebugEvent(
      WebSocketDebugEvent(
        direction: 'system',
        action: 'reconnect_scheduled',
        conversationId: _conversationId,
        userId: _userId,
        status: 'scheduled',
        details: 'reason=$reason delaySec=$delaySeconds attempt=${_reconnectAttempts + 1}',
      ),
    );

    _reconnectTimer = Timer(delay, () {
      if (_manualDisconnect) return;
      final token = _authTokenForReconnect;
      if (token == null || token.isEmpty) return;

      _reconnectAttempts += 1;
      unawaited(
        initialize(
          conversationId: _conversationId,
          userId: _userId,
          encryptionKey: _encryptionKey,
          authToken: token,
          resetReconnectState: false,
        ),
      );
    });
  }

  /// Create a new conversation (private or group)
  Future<void> createConversation({
    required String type,
    required List<String> participantIds,
  }) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    _stompClient?.send(
      destination: '/app/conversation.create',
      body: jsonEncode({
        'type': type,
        'participantIds': participantIds,
      }),
    );
    _recordDebugEvent(
      WebSocketDebugEvent(
        direction: 'outbound',
        action: 'conversation_create',
        destination: '/app/conversation.create',
        conversationId: _conversationId,
        userId: _userId,
        messageType: type,
        details: 'participants=${participantIds.length}',
      ),
    );
  }

  /// Join a conversation room (payload is raw conversation id string)
  void joinConversation(String conversationId) {
    if (!isConnected) return;
    _stompClient?.send(
      destination: '/app/conversation.join',
      body: conversationId,
    );
    _recordDebugEvent(
      WebSocketDebugEvent(
        direction: 'outbound',
        action: 'conversation_join',
        destination: '/app/conversation.join',
        conversationId: conversationId,
        userId: _userId,
      ),
    );
  }

  /// Send encrypted message
  Future<void> sendMessage(
    String content,
    String clientMsgId, {
    String messageType = 'TEXT',
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    try {
      // Create message payload
      final messagePayload = {
        'clientMsgId': clientMsgId,
        'conversationId': _conversationId,
        'type': messageType,
        'content': content,
        'mediaUrl': mediaUrl,
        if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
          'replyToMessageId': replyToMessageId,
      };

      // Send via WebSocket to /app/chat.send
      _stompClient?.send(
        destination: '/app/chat.send',
        body: jsonEncode(messagePayload),
      );

      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'outbound',
          action: 'chat_send',
          destination: '/app/chat.send',
          conversationId: _conversationId,
          userId: _userId,
          messageType: messageType,
          clientMsgId: clientMsgId,
          status: 'sent',
          details: 'contentLength=${content.length}',
        ),
      );

      print('Message sent: $clientMsgId');
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'chat_send',
          destination: '/app/chat.send',
          conversationId: _conversationId,
          userId: _userId,
          messageType: messageType,
          clientMsgId: clientMsgId,
          status: 'error',
          details: e.toString(),
        ),
      );
      printDebugReportToTerminal(
        conversationId: _conversationId,
        userId: _userId,
        notes: 'chat_send_error',
        force: true,
      );
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(bool isTyping) {
    if (!isConnected) return;

    try {
      final payload = {
        'conversationId': _conversationId,
        'isTyping': isTyping,
      };

      _stompClient?.send(
        destination: '/app/chat.typing',
        body: jsonEncode(payload),
      );
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'outbound',
          action: 'chat_typing',
          destination: '/app/chat.typing',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'TYPING',
          details: 'isTyping=$isTyping',
        ),
      );
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'chat_typing',
          destination: '/app/chat.typing',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'TYPING',
          status: 'error',
          details: e.toString(),
        ),
      );
      print('Error sending typing indicator: $e');
    }
  }

  void sendReaction({
    required String messageId,
    required String emoji,
  }) {
    if (!isConnected) return;
    if (messageId.trim().isEmpty) return;

    try {
      final payload = {
        'messageId': messageId,
        'emoji': emoji,
      };

      _stompClient?.send(
        destination: '/app/chat.react',
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Ignore optimistic reaction transport failures.
    }
  }

  /// Mark messages as read
  void markAsRead() {
    if (!isConnected) return;

    try {
      final payload = {
        'conversationId': _conversationId,
      };

      _stompClient?.send(
        destination: '/app/chat.read',
        body: jsonEncode(payload),
      );
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'outbound',
          action: 'chat_read',
          destination: '/app/chat.read',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'READ_RECEIPT',
          status: 'sent',
        ),
      );
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'chat_read',
          destination: '/app/chat.read',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'READ_RECEIPT',
          status: 'error',
          details: e.toString(),
        ),
      );
      print('Error marking as read: $e');
    }
  }

  void sendDeliveredAck(String messageId) {
    if (!isConnected || messageId.trim().isEmpty) return;

    try {
      _stompClient?.send(
        destination: '/app/chat.delivered',
        body: jsonEncode({'messageId': messageId}),
      );
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'outbound',
          action: 'chat_delivered',
          destination: '/app/chat.delivered',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'DELIVERED',
          status: 'sent',
          details: 'messageId=$messageId',
        ),
      );
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'chat_delivered',
          destination: '/app/chat.delivered',
          conversationId: _conversationId,
          userId: _userId,
          messageType: 'DELIVERED',
          status: 'error',
          details: e.toString(),
        ),
      );
    }
  }

  void _subscribeCoreTopics(String conversationId) {
    _unsubscribeAll();

    _subscribeDestination(
      '/topic/conversation/$conversationId',
      action: 'topic_conversation',
    );
    _subscribeDestination(
      '/topic/conversation/$conversationId/typing',
      action: 'topic_typing',
    );
    _subscribeDestination(
      '/topic/conversation/$conversationId/read',
      action: 'topic_read',
    );
    _subscribeDestination(
      '/topic/conversation/$conversationId/react',
      action: 'topic_react',
    );
    _subscribeDestination(
      '/user/queue/messages',
      action: 'queue_messages',
    );
    _subscribeDestination(
      '/user/queue/read-status',
      action: 'queue_read_status',
    );
    _subscribeDestination(
      '/user/queue/conversation.created',
      action: 'queue_conversation_created',
    );
    _subscribeDestination(
      '/user/queue/message-delivered',
      action: 'queue_message_delivered',
    );
    _subscribeDestination(
      '/user/queue/messages.sync',
      action: 'queue_messages_sync',
    );
  }

  void _subscribeDestination(
    String destination, {
    required String action,
  }) {
    final client = _stompClient;
    if (client == null) return;

    final unsubscribe = client.subscribe(
      destination: destination,
      callback: (frame) {
        _handleStompFrame(destination, frame, action: action);
      },
    );
    _unsubscribers.add(unsubscribe);

    _recordDebugEvent(
      WebSocketDebugEvent(
        direction: 'system',
        action: 'subscribe',
        destination: destination,
        conversationId: _conversationId,
        userId: _userId,
        status: 'ok',
        details: action,
      ),
    );
  }

  void _handleStompFrame(
    String destination,
    StompFrame frame, {
    required String action,
  }) {
    try {
      final body = frame.body;
      if (body == null || body.trim().isEmpty) {
        _recordDebugEvent(
          WebSocketDebugEvent(
            direction: 'inbound',
            action: action,
            destination: destination,
            conversationId: _conversationId,
            userId: _userId,
            status: 'empty',
          ),
        );
        return;
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['messages'] is List) {
          _handleSyncedMessages(decoded['messages'] as List<dynamic>);
          return;
        }

        _recordDebugEvent(
          WebSocketDebugEvent(
            direction: 'inbound',
            action: action,
            destination: destination,
            conversationId:
                decoded['conversationId']?.toString() ?? _conversationId,
            userId: decoded['senderId']?.toString() ?? _userId,
            messageType: decoded['type']?.toString(),
            clientMsgId: decoded['clientMsgId']?.toString(),
            status: frame.command,
          ),
        );
        if (!_isEventForActiveConversation(decoded, action: action)) {
          _recordDebugEvent(
            WebSocketDebugEvent(
              direction: 'system',
              action: 'event_ignored_other_conversation',
              destination: destination,
              conversationId: _conversationId,
              userId: _userId,
              status: 'ignored',
              details:
                  'action=$action eventConv=${_extractConversationId(decoded) ?? '-'} activeConv=$_conversationId',
            ),
          );
          return;
        }
        _handleIncomingMessage(decoded, action: action);
        return;
      }

      if (decoded is List) {
        _handleSyncedMessages(decoded);
        return;
      }

      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'inbound',
          action: action,
          destination: destination,
          conversationId: _conversationId,
          userId: _userId,
          status: 'non_map',
          details: body,
        ),
      );
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'socket_parse',
          destination: destination,
          conversationId: _conversationId,
          userId: _userId,
          status: 'error',
          details: e.toString(),
        ),
      );
      print('Error parsing STOMP frame: $e');
    }
  }

  void _unsubscribeAll() {
    for (final unsubscribe in _unsubscribers) {
      try {
        unsubscribe();
      } catch (_) {
        // no-op
      }
    }
    _unsubscribers.clear();
  }

  void _handleIncomingMessage(Map<String, dynamic> data, {String? action}) {
    final type = (data['type']?.toString().toUpperCase()) ?? 
        (action == 'topic_read' ? 'READ_RECEIPT' : 
     action == 'topic_typing' ? 'TYPING' :
     action == 'topic_react' ? 'REACTION' : 'MESSAGE');

    switch (type) {
      case 'MESSAGE':
        _handleChatMessage(data);
        break;
      case 'TYPING':
        _handleTypingIndicator(data);
        break;
      case 'READ_RECEIPT':
        _handleReadReceipt(data);
        break;
      case 'DELIVERED':
        _handleDeliveredReceipt(data);
        break;
      case 'REACTION':
        _handleReaction(data);
        break;
      case 'USER_ONLINE':
      case 'PRESENCE':
        _handlePresenceIndicator(data);
        break;
      case 'ERROR':
        _handleError(data);
        break;
      default:
        _recordDebugEvent(
          WebSocketDebugEvent(
            direction: 'inbound',
            action: 'unknown_message_type',
            conversationId: _conversationId,
            userId: _userId,
            messageType: type.toString(),
            details: data.toString(),
          ),
        );
        print('Unknown message type: $type');
    }
  }

  /// Handle received chat message
  void _handleChatMessage(Map<String, dynamic> data) {
    try {
      final eventConversationId =
          _extractConversationId(data) ?? _conversationId;

      String? resolvedContent = data['content'] as String?;
      if (resolvedContent == null || resolvedContent.isEmpty) {
        resolvedContent = data['text'] as String?;
      }
      if (resolvedContent == null || resolvedContent.isEmpty) {
        final payload = data['payload'];
        if (payload is Map<String, dynamic>) {
          resolvedContent = payload['text'] as String?;
        }
      }
      String content = resolvedContent ?? '';

      // Decrypt if encrypted
      if (data['isEncrypted'] == true && data['encryptedContent'] != null) {
        try {
          content = _encryptionService.decryptAES256GCM(
            data['encryptedContent'],
            data['encryptionIv'],
            _encryptionKey,
          );
        } catch (e) {
          print('Error decrypting message: $e');
          content = '[Encrypted message - decryption failed]';
        }
      }

      final message = ChatMessage(
        id: data['id'] ?? '',
        clientMsgId: data['clientMsgId'] ?? '',
        conversationId: eventConversationId,
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Unknown',
        senderAvatar: data['senderAvatar'],
        content: content,
        type: _parseWsMessageType(data['type'] as String?),
        mediaUrl: data['mediaUrl'],
        isRead: data['isRead'] ?? false,
        status: (data['status']?.toString() ?? 'SENT').toUpperCase(),
        timestamp: _parseServerDateTimeToLocal(data['createdAt']),
        replyToMessageId: data['replyToMessageId']?.toString(),
        reactions: (data['reactions'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const <String, String>{},
      );

      final messages = List<ChatMessage>.from(messageNotifier.value);
      final exists = messages.any((m) =>
          (message.id.isNotEmpty && m.id == message.id) ||
          (message.clientMsgId.isNotEmpty && m.clientMsgId == message.clientMsgId));
      if (exists) return;

      messages.add(message);
      messageNotifier.value = [...messages];

      // Auto mark as read if not from current user, and not already a read receipt event
      final typeString = data['type']?.toString().toUpperCase() ?? '';
      final statusString = data['status']?.toString().toUpperCase() ?? '';
      final isReceiptEvent = typeString == 'READ_RECEIPT' || statusString == 'READ_RECEIPT';

      if (!isReceiptEvent && message.senderId != _userId) {
        if (message.id.isNotEmpty) {
          sendDeliveredAck(message.id);
        }
        markAsRead();
      }

      print('Message received: ${message.id}');
    } catch (e) {
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'error',
          action: 'chat_message_handle',
          conversationId: _conversationId,
          userId: _userId,
          status: 'error',
          details: e.toString(),
        ),
      );
      print('Error handling chat message: $e');
    }
  }

  static MessageType _parseWsMessageType(String? typeStr) {
    if (typeStr == null) return MessageType.text;
    switch (typeStr.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'AUDIO':
      case 'VOICE':
        return MessageType.file; // Since audio doesn't exist on MessageType, mapping to file
      case 'FILE':
      case 'DOCUMENT':
        return MessageType.file;
      case 'LOCATION':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  /// Handle typing indicator
  void _handleTypingIndicator(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] ?? '';
      final isTyping = data['isTyping'] ?? false;

      final typing = Map<String, bool>.from(typingNotifier.value);
      if (isTyping) {
        typing[userId] = true;
      } else {
        typing.remove(userId);
      }

      typingNotifier.value = typing;
      print('User $userId typing: $isTyping');
    } catch (e) {
      print('Error handling typing indicator: $e');
    }
  }

  /// Handle read receipt
  void _handleReadReceipt(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] ?? '';
      print('User $userId read the messages');
      // Update message UI to show read status
    } catch (e) {
      print('Error handling read receipt: $e');
    }
  }

  void _handleDeliveredReceipt(Map<String, dynamic> data) {
    try {
      final messageId =
          data['messageId']?.toString() ?? data['id']?.toString() ?? '';
      final clientMsgId = data['clientMsgId']?.toString() ?? '';
      if (messageId.isEmpty && clientMsgId.isEmpty) return;

      final status =
          (data['status']?.toString() ?? 'DELIVERED').toUpperCase();

      final updated = List<ChatMessage>.from(messageNotifier.value);
      var changed = false;
      for (var i = 0; i < updated.length; i++) {
        final m = updated[i];
        if (m.id == messageId ||
            m.clientMsgId == messageId ||
            (clientMsgId.isNotEmpty && m.clientMsgId == clientMsgId)) {
          updated[i] = m.copyWith(
            status: status,
            isRead: status == 'READ' ? true : m.isRead,
          );
          changed = true;
        }
      }

      if (changed) {
        messageNotifier.value = updated;
      }

      deliveryReceiptNotifier.value = {
        'messageId': messageId,
        'status': status,
      };
    } catch (e) {
      print('Error handling delivered receipt: $e');
    }
  }

  void _handlePresenceIndicator(Map<String, dynamic> data) {
    try {
      final userId = data['userId']?.toString() ?? '';
      final isOnline = data['isOnline'] == true;
      if (userId.isNotEmpty) {
        final presence = Map<String, bool>.from(presenceNotifier.value);
        presence[userId] = isOnline;
        presenceNotifier.value = presence;
      }
    } catch (e) {
      print('Error handling presence indicator: $e');
    }
  }

  void _handleReaction(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString() ??
        data['id']?.toString() ??
        (data['message'] is Map
            ? (data['message']['id']?.toString() ?? '')
            : '');
    if (messageId.isEmpty) return;

    final reactionsRaw = data['reactions'] ??
        (data['message'] is Map ? data['message']['reactions'] : null);
    final reactions = (reactionsRaw is Map)
        ? reactionsRaw.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : <String, String>{};

    reactionNotifier.value = {
      'messageId': messageId,
      'reactions': reactions,
    };
  }

  void _handleSyncedMessages(List<dynamic> rawMessages) {
    final syncedMaps = rawMessages
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    for (final data in syncedMaps) {
      if (!_isEventForActiveConversation(data, action: 'queue_messages_sync')) {
        continue;
      }
      _handleChatMessage(data);
    }
  }

  bool _isEventForActiveConversation(
    Map<String, dynamic> data, {
    String? action,
  }) {
    if (action != null && action.startsWith('topic_')) {
      return true;
    }

    final eventConversationId = _extractConversationId(data);
    if (eventConversationId == null || eventConversationId.isEmpty) {
      return false;
    }

    return eventConversationId == _conversationId;
  }

  String? _extractConversationId(Map<String, dynamic> data) {
    final direct = data['conversationId']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final conversation = data['conversation'];
    if (conversation is Map<String, dynamic>) {
      final id = conversation['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }

    final message = data['message'];
    if (message is Map<String, dynamic>) {
      final id = message['conversationId']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }

    return null;
  }

  /// Handle WebSocket errors
  void _handleError(Map<String, dynamic> data) {
    final errorMessage = data['message'] ?? 'Unknown error';
    _recordDebugEvent(
      WebSocketDebugEvent(
        direction: 'error',
        action: 'backend_error',
        conversationId: _conversationId,
        userId: _userId,
        messageType: data['type']?.toString(),
        status: 'error',
        details: errorMessage.toString(),
      ),
    );
    printDebugReportToTerminal(
      conversationId: _conversationId,
      userId: _userId,
      notes: 'backend_error',
      force: true,
    );
    print('WebSocket error: $errorMessage');
  }

  /// Close connection
  void close() {
    try {
      _manualDisconnect = true;
      _reconnectTimer?.cancel();
      _unsubscribeAll();
      _stompClient?.deactivate();
      _stompClient = null;
      _recordDebugEvent(
        WebSocketDebugEvent(
          direction: 'system',
          action: 'close',
          conversationId: _conversationId,
          userId: _userId,
          status: 'closed',
        ),
      );
      isConnectedNotifier.value = false;
      messageNotifier.value = [];
      typingNotifier.value = {};
      reactionNotifier.value = null;
      presenceNotifier.value = {};
      print('WebSocket closed');
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    close();
    messageNotifier.dispose();
    isConnectedNotifier.dispose();
    typingNotifier.dispose();
    deliveryReceiptNotifier.dispose();
    reactionNotifier.dispose();
    presenceNotifier.dispose();
  }
}

/// Chat message data model
class ChatMessage {
  final String id;
  final String clientMsgId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final bool isRead;
  final String status;
  final DateTime timestamp;
  final String? replyToMessageId;
  final Map<String, String> reactions;

  ChatMessage({
    required this.id,
    required this.clientMsgId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.isRead,
    required this.status,
    required this.timestamp,
    this.replyToMessageId,
    this.reactions = const <String, String>{},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      clientMsgId: json['clientMsgId'],
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: json['mediaUrl'],
      isRead: json['isRead'] ?? false,
      status: (json['status']?.toString() ?? 'SENT').toUpperCase(),
      timestamp: _parseServerDateTimeToLocal(json['createdAt']),
      replyToMessageId: json['replyToMessageId']?.toString(),
      reactions: (json['reactions'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const <String, String>{},
    );
  }

  ChatMessage copyWith({
    bool? isRead,
    String? status,
    String? replyToMessageId,
    Map<String, String>? reactions,
  }) {
    return ChatMessage(
      id: id,
      clientMsgId: clientMsgId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      timestamp: timestamp,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
    );
  }
}

enum MessageType { text, image, video, file, location }

class WebSocketDebugEvent {
  final DateTime timestamp;
  final String direction;
  final String action;
  final String? destination;
  final String? conversationId;
  final String? userId;
  final String? messageType;
  final String? clientMsgId;
  final String? status;
  final String? details;

  WebSocketDebugEvent({
    DateTime? timestamp,
    required this.direction,
    required this.action,
    this.destination,
    this.conversationId,
    this.userId,
    this.messageType,
    this.clientMsgId,
    this.status,
    this.details,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'direction': direction,
      'action': action,
      'destination': destination,
      'conversationId': conversationId,
      'userId': userId,
      'messageType': messageType,
      'clientMsgId': clientMsgId,
      'status': status,
      'details': details,
    };
  }
}

/// Service for retrieving conversations and messages from REST API
class ConversationService {
  /// Get user's conversations
  static Future<List<ConversationInfo>> getConversations({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/conversations?page=$page&size=$size',
      );

      if (response is Map && response.containsKey('content')) {
        return (response['content'] as List)
            .map((json) => ConversationInfo.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Get conversation history
  static Future<List<ChatMessage>> getConversationHistory({
    required String conversationId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '/conversations/$conversationId/messages?page=$page&size=$size',
      );

      if (response is Map && response.containsKey('content')) {
        return (response['content'] as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching conversation history: $e');
      rethrow;
    }
  }

  /// Create new conversation
  static Future<ConversationInfo> createConversation({
    required List<String> participantIds,
    String? name,
  }) async {
    try {
      final response = await ApiService.post('/conversations', {
        'participantIds': participantIds,
        'name': name,
      });

      return ConversationInfo.fromJson(response);
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }
}

/// Conversation information data model
class ConversationInfo {
  final String id;
  final String? name;
  final List<ConversationParticipant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? encryptionKey;

  ConversationInfo({
    required this.id,
    this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.encryptionKey,
  });

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    return ConversationInfo(
      id: json['id'],
      name: json['name'],
      participants: (json['participants'] as List)
          .map((p) => ConversationParticipant.fromJson(p))
          .toList(),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: _parseServerDateTimeToLocal(
        json['lastMessageTime'] ?? json['lastMessageAt'],
      ),
      unreadCount: json['unreadCount'] ?? 0,
      encryptionKey: json['encryptionKey'],
    );
  }
}

class ConversationParticipant {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeenAt;

  ConversationParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.isOnline,
    this.lastSeenAt,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      isOnline: json['isOnline'] ?? false,
      lastSeenAt: json['lastSeenAt'] != null
          ? _parseServerDateTimeToLocal(json['lastSeenAt'])
          : null,
    );
  }
}
