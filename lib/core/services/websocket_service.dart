import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'encryption_service.dart';
import 'api_service.dart';

/// WebSocket service for real-time encrypted messaging
class WebSocketService {
  // Spring endpoint exposed for chat websocket handshake.
  static const String wsBaseUrl = 'wss://ispilo-backend-32613e7af752.herokuapp.com/ws/chat';

  late WebSocketChannel _channel;
  late String _conversationId;
  late String _userId;
  late String _encryptionKey;
  late EncryptionService _encryptionService;

  final ValueNotifier<List<ChatMessage>> messageNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  final ValueNotifier<Map<String, bool>> typingNotifier = ValueNotifier({});

  bool get isConnected => isConnectedNotifier.value;

  /// Initialize WebSocket connection with authentication
  Future<void> initialize({
    required String conversationId,
    required String userId,
    required String encryptionKey,
    required String authToken,
  }) async {
    _conversationId = conversationId;
    _userId = userId;
    _encryptionKey = encryptionKey;
    _encryptionService = EncryptionService();

    try {
      // Connect to WebSocket with JWT token (IO implementation for non-web platforms)
      _channel = IOWebSocketChannel.connect(
        Uri.parse('$wsBaseUrl?token=$authToken'),
      );

      isConnectedNotifier.value = true;
      _listenToMessages();
  joinConversation(conversationId);
      print('WebSocket connected to conversation: $conversationId');
    } catch (e) {
      isConnectedNotifier.value = false;
      print('WebSocket connection failed: $e');
      rethrow;
    }
  }

  /// Create a new conversation (private or group)
  Future<void> createConversation({
    required String type,
    required List<String> participantIds,
  }) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    _channel.sink.add(jsonEncode({
      'destination': '/app/conversation.create',
      'payload': {
        'type': type,
        'participantIds': participantIds,
      },
    }));
  }

  /// Join a conversation room (payload is raw conversation id string)
  void joinConversation(String conversationId) {
    if (!isConnected) return;
    _channel.sink.add(jsonEncode({
      'destination': '/app/conversation.join',
      'payload': conversationId,
    }));
  }

  /// Send encrypted message
  Future<void> sendMessage(String content, String clientMsgId) async {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }

    try {
      // Encrypt message content
      final encryptedContent = _encryptionService.encryptAES256GCM(
        content,
        _encryptionKey,
      );

      // Create message payload
      final messagePayload = {
        'conversationId': _conversationId,
        'content': content,
        'encryptionKey': _encryptionKey,
        // Optional encrypted fields for backend compatibility with service logic.
        'encryptedContent': encryptedContent['encrypted'],
        'encryptionIv': encryptedContent['iv'],
        'type': 'TEXT',
        'clientMsgId': clientMsgId,
      };

      // Send via WebSocket to /app/chat.send
      _channel.sink.add(jsonEncode({
        'destination': '/app/chat.send',
        'payload': messagePayload,
      }));

      print('Message sent: $clientMsgId');
    } catch (e) {
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

      _channel.sink.add(jsonEncode({
        'destination': '/app/chat.typing',
        'payload': payload,
      }));
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  /// Mark messages as read
  void markAsRead() {
    if (!isConnected) return;

    try {
      final payload = {
        'conversationId': _conversationId,
      };

      _channel.sink.add(jsonEncode({
        'destination': '/app/chat.read',
        'payload': payload,
      }));
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  /// Listen to incoming messages
  void _listenToMessages() {
    _channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          _handleIncomingMessage(data);
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        isConnectedNotifier.value = false;
      },
      onDone: () {
        print('WebSocket closed');
        isConnectedNotifier.value = false;
      },
    );
  }

  /// Handle incoming message based on type
  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'] ?? 'MESSAGE';

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
      case 'ERROR':
        _handleError(data);
        break;
      default:
        print('Unknown message type: $type');
    }
  }

  /// Handle received chat message
  void _handleChatMessage(Map<String, dynamic> data) {
    try {
      String content = data['content'] ?? '';

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
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Unknown',
        senderAvatar: data['senderAvatar'],
        content: content,
        type: MessageType.text,
        mediaUrl: data['mediaUrl'],
        isRead: data['isRead'] ?? false,
        timestamp: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      );

      // Add to message list
      final messages = messageNotifier.value;
      messages.add(message);
      messageNotifier.value = [...messages];

      // Auto mark as read if not from current user
      if (message.senderId != _userId) {
        markAsRead();
      }

      print('Message received: ${message.id}');
    } catch (e) {
      print('Error handling chat message: $e');
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

  /// Handle WebSocket errors
  void _handleError(Map<String, dynamic> data) {
    final errorMessage = data['message'] ?? 'Unknown error';
    print('WebSocket error: $errorMessage');
  }

  /// Close connection
  void close() {
    try {
      _channel.sink.close();
      isConnectedNotifier.value = false;
      messageNotifier.value = [];
      typingNotifier.value = {};
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
  }
}

/// Chat message data model
class ChatMessage {
  final String id;
  final String clientMsgId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final bool isRead;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.clientMsgId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.isRead,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      clientMsgId: json['clientMsgId'],
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
      timestamp: DateTime.parse(json['createdAt']),
    );
  }
}

enum MessageType { text, image, video, file, location }

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
      lastMessageTime: DateTime.parse(json['lastMessageTime'] ?? DateTime.now().toIso8601String()),
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

  ConversationParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.isOnline,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      isOnline: json['isOnline'] ?? false,
    );
  }
}
