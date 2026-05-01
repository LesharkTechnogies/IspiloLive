import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/conversation_service.dart';
import '../../core/services/message_service.dart';
import '../../core/services/websocket_service.dart' hide ConversationService;
import '../../model/social_model.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/media_download_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Current user id resolved from stored profile when available.
  String _currentUserId = 'current_user';

  // Freeze peer identity for this screen instance to avoid cross-chat header shifts.
  late final String _peerUserId;
  String _peerName = 'User';
  String _peerAvatar = '';
  bool _peerIsOnline = false;
  DateTime? _peerLastSeenAt;
  bool _peerIsVerified = false;
  String? _replyToMessageId;
  String? _replyPreviewText;
  String? _pinnedMessageId;

  // Messages in local UI shape: {id, text, isSentByMe, timestamp (DateTime), isRead}
  final List<Map<String, dynamic>> _messages = [];

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  Timer? _pendingRetryTimer;
  Timer? _messageFetchRetryTimer;

  File? _pendingAttachment;
  String? _pendingAttachmentType; // 'image', 'video', 'audio', etc.
  int? _pendingAudioDurationMs;

  SharedPreferences? _prefs;
  WebSocketService? _webSocketService;
  String? _authToken;

  static const String _pendingStorageKeyPrefix = 'pending_messages_';
  static const String _messageCacheKeyPrefix = 'cached_messages_';
  static const String _chatUserCacheKeyPrefix = 'chat_user_';
  static const String _pinnedMessageKeyPrefix = 'pinned_message_';
  static const String _prefOfflineMessages = 'pref_offline_messages';
  static const Duration _backgroundRetryInterval = Duration(minutes: 1);
  static const int _maxAutoRetryAttempts = 3;
  static const Duration _markReadCooldown = Duration(seconds: 30);
  DateTime? _lastMarkReadAttemptAt;
  bool _offlineMessagesEnabled = true;

  String get _cacheScope => '${_currentUserId}_$_conversationId';
  String get _messageCacheKey => '$_messageCacheKeyPrefix$_cacheScope';
  String get _pendingMessagesKey => '$_pendingStorageKeyPrefix$_cacheScope';
  String get _chatUserCacheKey => '$_chatUserCacheKeyPrefix$_cacheScope';
  String get _pinnedMessageKey => '$_pinnedMessageKeyPrefix$_cacheScope';

  String? get _existingConversationId {
    final idVal = widget.conversation['id'];
    final id = idVal?.toString().trim() ?? '';
    if (id.isEmpty || id.startsWith('conv_')) return null;
    return id;
  }

  String get _conversationId {
    final existingId = _existingConversationId;
    if (existingId != null) return existingId;
    final fallback = _peerUserId.isNotEmpty
        ? _peerUserId
        : (widget.conversation['userId']?.toString() ?? 'unknown');
    return 'conv_$fallback';
  }

  Future<String?> _ensureConversationId() async {
    final existingId = _existingConversationId;
    if (existingId != null) return existingId;

  final targetUserId = _peerUserId.trim();
  if (targetUserId.isEmpty) return null;

    try {
      final created = await ConversationService.instance.getOrCreateConversation(
        targetUserId: targetUserId,
        targetName: widget.conversation['name']?.toString() ?? 'Conversation',
        targetAvatar: widget.conversation['avatar']?.toString() ?? '',
      );

      final newId = created['id']?.toString().trim();
      if (newId == null || newId.isEmpty) return null;

      // Merge only conversation-related fields; keep peer identity stable.
      widget.conversation['id'] = newId;
      if (created['encryptionKey'] != null) {
        widget.conversation['encryptionKey'] = created['encryptionKey'];
      }
      if (created['isGroup'] != null) {
        widget.conversation['isGroup'] = created['isGroup'];
      }
      if (created['isOnline'] != null) {
        _peerIsOnline = created['isOnline'] == true;
        widget.conversation['isOnline'] = _peerIsOnline;
      }
      if (created['lastSeenAt'] != null) {
        _peerLastSeenAt = _parseServerDateTimeToLocal(created['lastSeenAt']);
        widget.conversation['lastSeenAt'] = created['lastSeenAt'];
      }
      widget.conversation['userId'] = targetUserId;

      unawaited(_persistChatUserCache());
      return newId;
    } catch (_) {
      return null;
    }
  }

  String? get _profileUserId {
    final id = _peerUserId;
    return id.trim().isEmpty ? null : id;
  }

  void _openConversationProfile() {
    final userId = _profileUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details are unavailable')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'userId': userId},
    );
  }

  @override
  void initState() {
    super.initState();
    _peerUserId = widget.conversation['userId']?.toString().trim() ?? '';
    _peerName = widget.conversation['name']?.toString().trim().isNotEmpty == true
        ? widget.conversation['name']!.toString()
        : 'User';
    _peerAvatar = widget.conversation['avatar']?.toString() ?? '';
    _peerIsOnline = widget.conversation['isOnline'] == true;
  _peerLastSeenAt = widget.conversation['lastSeenAt'] != null
    ? _parseServerDateTimeToLocal(widget.conversation['lastSeenAt'])
    : null;
    _peerIsVerified = widget.conversation['isVerified'] == true;
    _connectivity = Connectivity();
    _messageController.addListener(_handleComposerChanged);
    _initializeAsyncResources();
  }

  void _startBackgroundRetryServices() {
    _pendingRetryTimer?.cancel();
    _messageFetchRetryTimer?.cancel();

    _pendingRetryTimer = Timer.periodic(
      _backgroundRetryInterval,
      (_) {
        unawaited(_flushPendingMessages());
      },
    );

    // Background polling fallback acting as a real-time WebSocket connection
    _messageFetchRetryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_existingConversationId != null && _isOnline) {
          unawaited(_loadConversationMessages());
        }
      },
    );
  }

  Future<void> _persistMessagesCache() async {
    if (!_offlineMessagesEnabled) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final key = _messageCacheKey;
    final payload = _messages
        .map((m) => {
              'id': m['id'],
              'type': m['type'],
              'text': m['text'],
              'mediaPath': m['mediaPath'],
              'documentName': m['documentName'],
              'durationMs': m['durationMs'],
        'replyToMessageId': m['replyToMessageId'],
        'reactions': m['reactions'] ?? const <String, String>{},
              'isSentByMe': m['isSentByMe'] ?? false,
              'timestamp':
                  (m['timestamp'] as DateTime?)?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'isRead': m['isRead'] ?? false,
              'status': m['status'] ?? 'sent',
            })
        .toList();

    await prefs.setString(key, jsonEncode(payload));
  await _persistChatUserCache();
  }

  Future<void> _restoreCachedMessages() async {
    if (!_offlineMessagesEnabled) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final key = _messageCacheKey;
    final encoded = prefs.getString(key);
    if (encoded == null || encoded.isEmpty) return;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      final restored = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        DateTime timestamp;
        try {
          timestamp = _parseServerDateTimeToLocal(map['timestamp']);
        } catch (_) {
          timestamp = DateTime.now();
        }

        restored.add({
          'id': map['id'],
          'type': map['type'] ?? 'text',
          'text': map['text'] ?? '',
          'mediaPath': map['mediaPath'],
          'documentName': map['documentName'],
          'durationMs': map['durationMs'],
      'replyToMessageId': map['replyToMessageId'],
      'reactions': (map['reactions'] as Map?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        const <String, String>{},
          'isSentByMe': map['isSentByMe'] ?? false,
          'timestamp': timestamp,
          'isRead': map['isRead'] ?? false,
          'status': map['status'] ?? 'sent',
        });
      }

      if (restored.isEmpty || !mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Ignore malformed cached payload.
    }
  }

  Future<void> _persistChatUserCache() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final payload = {
      'id': widget.conversation['id'],
      'userId': _peerUserId,
      'name': _peerName,
      'avatar': _peerAvatar,
      'isOnline': _peerIsOnline,
      'lastSeenAt': _peerLastSeenAt?.toUtc().toIso8601String(),
      'isVerified': _peerIsVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_chatUserCacheKey, jsonEncode(payload));
  }

  Future<void> _restoreChatUserCache() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final encoded = prefs.getString(_chatUserCacheKey);
    if (encoded == null || encoded.isEmpty) return;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        final cachedUserId = decoded['userId']?.toString().trim() ?? '';
        // Only restore if cache belongs to this peer.
        if (cachedUserId.isNotEmpty && cachedUserId == _peerUserId) {
          if ((decoded['name']?.toString().trim().isNotEmpty ?? false)) {
            _peerName = decoded['name'].toString();
          }
          _peerAvatar = decoded['avatar']?.toString() ?? _peerAvatar;
          _peerIsOnline = decoded['isOnline'] == true;
      _peerLastSeenAt = decoded['lastSeenAt'] != null
        ? _parseServerDateTimeToLocal(decoded['lastSeenAt'])
        : _peerLastSeenAt;
          _peerIsVerified = decoded['isVerified'] == true;
          if (decoded['id'] != null &&
              (widget.conversation['id']?.toString().trim().isEmpty ?? true)) {
            widget.conversation['id'] = decoded['id'];
          }
        }
      }
    } catch (_) {
      // Ignore malformed cached payload.
    }
  }

  Future<void> _retryMessageById(String messageId) async {
    final idx = _messages.indexWhere((m) => m['id']?.toString() == messageId);
    if (idx == -1) return;

    final message = _messages[idx];
    if (mounted) {
      setState(() {
        _messages[idx]['status'] = _isOnline ? 'sending' : 'pending';
      });
    }

    final payload = {
      'id': message['id'],
      'type': message['type'],
      'text': message['text'],
      'mediaPath': message['mediaPath'],
      'documentName': message['documentName'],
      'durationMs': message['durationMs'],
      'replyToMessageId': message['replyToMessageId'],
      'reactions': message['reactions'] ?? const <String, String>{},
      'timestamp': (message['timestamp'] as DateTime?)?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    if (!_isOnline) {
      await _queuePendingMessage(payload);
      unawaited(_persistMessagesCache());
      return;
    }

    try {
      await _queuePendingMessage(payload);
      await _flushPendingMessages();
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages[idx]['status'] = 'failed';
        });
      }
    }

    unawaited(_persistMessagesCache());
  }

  Future<void> _removePendingMessageById(String messageId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

  final key = _pendingMessagesKey;
    final pendingList = prefs.getStringList(key) ?? [];
    if (pendingList.isEmpty) return;

    final filtered = <String>[];
    for (final encoded in pendingList) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        if (decoded['id']?.toString() == messageId) {
          continue;
        }
      } catch (_) {
        // Keep unparseable items to avoid accidental data loss.
      }
      filtered.add(encoded);
    }

    await prefs.setStringList(key, filtered);
  }

  Future<void> _loadConversationMessages() async {
    final convId = await _ensureConversationId();
    if (convId == null) {
      return;
    }

    // Always fetch messages from the production service.
    final fetched = await ConversationService.instance.fetchMessages(convId);

    var hasUnreadIncoming = false;
    final newMessages = <Map<String, dynamic>>[];

    for (final m in fetched.reversed) {
      final senderId = m['senderId'] as String? ?? '';
      final isSentByMe = senderId == _currentUserId;
      final isRead = m['isRead'] as bool? ?? false;

      if (!isSentByMe && !isRead) {
        hasUnreadIncoming = true;
      }

      final tsRaw = m['timestamp'];
      final ts = _parseServerDateTimeToLocal(tsRaw);

      final type = (m['mediaType'] as String?) ??
          ((m['text'] as String?)?.isNotEmpty == true ? 'text' : 'unknown');

      newMessages.add({
        'id': m['id'],
        'type': type,
        'text': m['text'] ?? '',
        'mediaPath': m['mediaPath'],
        'documentName': m['documentName'],
        'durationMs': m['durationMs'],
        'replyToMessageId': m['replyToMessageId'],
        'reactions': (m['reactions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
        'isSentByMe': isSentByMe,
        'timestamp': ts,
        'isRead': isRead,
        'status': 'sent',
      });
    }

    if (!mounted) return;

    setState(() {
      // Preserve local pending/sending messages
      final localMessages = _messages.where((m) => m['id'].toString().startsWith('local_')).toList();
      
      _messages.clear();
      _messages.addAll(newMessages);
      _messages.addAll(localMessages);
      
      // Sort by timestamp
      _messages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
    });
    unawaited(_persistMessagesCache());

    // Mark as read only when there are unread incoming messages from other users.
    if (hasUnreadIncoming) {
      final now = DateTime.now();
      if (_lastMarkReadAttemptAt == null ||
          now.difference(_lastMarkReadAttemptAt!) >= _markReadCooldown) {
        _lastMarkReadAttemptAt = now;

        try {
          await ConversationService.instance.markConversationRead(
            convId,
            _currentUserId,
          );
          _webSocketService?.markAsRead();

          if (mounted) {
            setState(() {
              for (final m in _messages) {
                if ((m['isSentByMe'] as bool? ?? false) == false) {
                  m['isRead'] = true;
                }
              }
            });
            unawaited(_persistMessagesCache());
          }
        } catch (_) {
          // Keep chat usable even when read endpoint is temporarily unavailable.
        }
      }
    }
  }

  Future<bool> _confirmMessageStored(String messageId) async {
    final convId = _existingConversationId;
    if (convId == null || messageId.trim().isEmpty) return false;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final fetched = await ConversationService.instance.fetchMessages(convId);
        final exists = fetched.any(
          (m) => (m['id']?.toString() ?? '') == messageId,
        );
        if (exists) return true;
      } catch (_) {
        // Ignore and retry quickly.
      }

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    return false;
  }

  void _handleComposerChanged() {
    _webSocketService?.sendTypingIndicator(
      _messageController.text.trim().isNotEmpty,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeAsyncResources() async {
    _prefs ??= await SharedPreferences.getInstance();
    _offlineMessagesEnabled = _prefs?.getBool(_prefOfflineMessages) ?? true;
    _hydrateCurrentUserFromPrefs();
    await _restoreChatUserCache();
    await _restorePinnedMessage();
    await _setupConnectivityMonitoring();
    await _restoreCachedMessages();
    await _restorePendingMessages();
    _startBackgroundRetryServices();
    unawaited(_loadConversationMessages());
    unawaited(_ensureWebSocketForMessaging());
  }

  Future<void> _persistPinnedMessage() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    if (_pinnedMessageId == null || _pinnedMessageId!.trim().isEmpty) {
      await prefs.remove(_pinnedMessageKey);
      return;
    }

    await prefs.setString(_pinnedMessageKey, _pinnedMessageId!);
  }

  Future<void> _restorePinnedMessage() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _pinnedMessageId = prefs.getString(_pinnedMessageKey);
  }

  void _hydrateCurrentUserFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;

    _authToken = prefs.getString('auth_token');
    final userProfile = prefs.getString('user_profile');
    if (userProfile == null || userProfile.isEmpty) return;

    try {
      final decoded = jsonDecode(userProfile) as Map<String, dynamic>;
      final id = decoded['id']?.toString();
      if (id != null && id.isNotEmpty) {
        _currentUserId = id;
      }
    } catch (_) {
      // Keep fallback id when profile JSON is unavailable/corrupt.
    }
  }

  Future<void> _initializeWebSocket() async {
    final token = _authToken;
    final encryptionKey = widget.conversation['encryptionKey']?.toString() ?? '';
    final conversationId = _existingConversationId;

    if (token == null || token.isEmpty) return;
    if (conversationId == null) return;

    try {
      _webSocketService?.dispose();
      _webSocketService = WebSocketService();

      await _webSocketService!.initialize(
        conversationId: conversationId,
        userId: _currentUserId,
        encryptionKey: encryptionKey,
        authToken: token,
      );

      _webSocketService!.messageNotifier.addListener(_handleWsMessageUpdate);
      _webSocketService!.isConnectedNotifier.addListener(_handleWsConnectionChanged);
      _webSocketService!.deliveryReceiptNotifier
          .addListener(_handleWsDeliveryReceiptUpdate);
    _webSocketService!.reactionNotifier.addListener(_handleWsReactionUpdate);
      _webSocketService!.presenceNotifier.addListener(_handleWsPresenceUpdate);
    } catch (_) {
      // WebSocket is optional; REST remains as fallback.
    }
  }

  Future<void> _ensureWebSocketForMessaging() async {
    if (_existingConversationId == null) return;
    final ws = _webSocketService;
    if (ws != null && ws.isConnected) return;
    await _initializeWebSocket();
  }

  void _handleWsConnectionChanged() {
    final ws = _webSocketService;
    if (ws == null || !mounted) return;
    
    // If chatting with self, immediately show online when connected
    if (ws.isConnected && _peerUserId == _currentUserId) {
      setState(() {
        _peerIsOnline = true;
        _peerLastSeenAt = DateTime.now();
      });
      unawaited(_persistChatUserCache());
    }

    if (ws.isConnected) {
      unawaited(_loadConversationMessages());
      unawaited(_flushPendingMessages());
    }
  }

  void _handleWsMessageUpdate() {
    final ws = _webSocketService;
    if (ws == null || !mounted) return;
    if (ws.messageNotifier.value.isEmpty) return;

    final activeConversationId = _existingConversationId;
    if (activeConversationId == null || activeConversationId.isEmpty) return;

    final incoming = ws.messageNotifier.value.last;
    if (incoming.conversationId != activeConversationId) {
      return;
    }

    final exists = _messages.any((m) =>
        m['id']?.toString() == incoming.id ||
        (m['text'] == incoming.content &&
            m['isSentByMe'] == (incoming.senderId == _currentUserId)));

    if (exists) return;

    setState(() {
      _messages.add({
        'id': incoming.id,
        'type': incoming.type.name,
        'text': incoming.content,
        'mediaPath': incoming.mediaUrl,
        'documentName': null,
        'durationMs': null,
        'replyToMessageId': incoming.replyToMessageId,
        'reactions': incoming.reactions,
        'isSentByMe': incoming.senderId == _currentUserId,
        'timestamp': incoming.timestamp,
        'isRead': incoming.isRead,
        'status': incoming.status.toLowerCase(),
      });
    });
    unawaited(_persistMessagesCache());
  }

  void _handleWsReactionUpdate() {
    final ws = _webSocketService;
    if (ws == null || !mounted) return;

    final payload = ws.reactionNotifier.value;
    if (payload == null) return;

    final messageId = payload['messageId']?.toString() ?? '';
    if (messageId.isEmpty) return;

    final reactions = (payload['reactions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        const <String, String>{};

    var changed = false;
    setState(() {
      for (var i = 0; i < _messages.length; i++) {
        if ((_messages[i]['id']?.toString() ?? '') == messageId) {
          _messages[i]['reactions'] = reactions;
          changed = true;
          break;
        }
      }
    });

    if (changed) {
      unawaited(_persistMessagesCache());
    }
  }

  void _handleWsDeliveryReceiptUpdate() {
    final ws = _webSocketService;
    if (ws == null || !mounted) return;

    final receipt = ws.deliveryReceiptNotifier.value;
    if (receipt == null) return;

    final messageId = receipt['messageId']?.toString() ?? '';
    final status = (receipt['status']?.toString() ?? 'DELIVERED').toLowerCase();
    if (messageId.isEmpty) return;

    var changed = false;
    setState(() {
      for (var i = 0; i < _messages.length; i++) {
        final id = _messages[i]['id']?.toString() ?? '';
        if (id == messageId) {
          _messages[i]['status'] = status;
          if (status == 'read') {
            _messages[i]['isRead'] = true;
          }
          changed = true;
        }
      }
    });

    if (changed) {
      unawaited(_persistMessagesCache());
    }
  }

  void _handleWsPresenceUpdate() {
    final ws = _webSocketService;
    if (ws == null || !mounted) return;

    final presence = ws.presenceNotifier.value;
    if (presence.containsKey(_peerUserId)) {
      setState(() {
        _peerIsOnline = presence[_peerUserId]!;
        if (_peerIsOnline) {
          _peerLastSeenAt = DateTime.now();
        }
      });
      unawaited(_persistChatUserCache());
    }
  }

  Future<void> _setupConnectivityMonitoring() async {
    final status = await _connectivity.checkConnectivity();
    final online = status.any((result) => result != ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }

    await _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((statusList) {
      final nowOnline =
          statusList.any((status) => status != ConnectivityResult.none);
      final wasOffline = !_isOnline && nowOnline;
      if (mounted) {
        setState(() {
          _isOnline = nowOnline;
        });
      }
      if (wasOffline) {
        unawaited(_loadConversationMessages());
        unawaited(_flushPendingMessages());
      }
    });
  }

  Future<void> _restorePendingMessages() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

  final key = _pendingMessagesKey;
    final pendingList = prefs.getStringList(key) ?? [];

    if (pendingList.isEmpty) return;

    for (final encoded in pendingList) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
  final timestamp = _parseServerDateTimeToLocal(decoded['timestamp']);

        setState(() {
          _messages.add({
            'id': decoded['id'],
            'type': decoded['type'],
            'text': decoded['text'],
            'mediaPath': decoded['mediaPath'],
            'documentName': decoded['documentName'],
            'durationMs': decoded['durationMs'],
            'replyToMessageId': decoded['replyToMessageId'],
            'reactions': const <String, String>{},
            'retryCount': decoded['retryCount'] ?? 0,
            'isSentByMe': true,
            'timestamp': timestamp,
            'isRead': false,
            'status': 'pending',
          });
        });
        unawaited(_persistMessagesCache());
      } catch (_) {
        // Skip invalid entries
      }
    }
  }

  Future<void> _flushPendingMessages() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

  final key = _pendingMessagesKey;
    final pendingList = prefs.getStringList(key) ?? [];

    if (pendingList.isEmpty) return;

    final List<String> failedMessages = [];

    for (final encoded in pendingList) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        final retryCount = (decoded['retryCount'] as num?)?.toInt() ?? 0;

        if (retryCount >= _maxAutoRetryAttempts) {
          if (mounted) {
            setState(() {
              final idx =
                  _messages.indexWhere((m) => m['id'] == decoded['id']);
              if (idx != -1) {
                _messages[idx]['status'] = 'failed';
                _messages[idx]['retryCount'] = retryCount;
              }
            });
          }
          continue;
        }

        final type = decoded['type'] as String?;
        final conversationId = await _ensureConversationId();
        if (conversationId == null) {
          failedMessages.add(
            jsonEncode({...decoded, 'retryCount': retryCount + 1}),
          );
          continue;
        }

        unawaited(_ensureWebSocketForMessaging());

        String? finalMediaUrl = decoded['mediaPath'] as String?;
        if (finalMediaUrl != null && !finalMediaUrl.startsWith('http')) {
          final isVideo = type == 'video';
          final uploaded = await CloudinaryService.uploadFile(finalMediaUrl, isVideo: isVideo, resourceType: 'auto');
          if (uploaded != null) {
            finalMediaUrl = uploaded;
          }
        }

        final sent = await ConversationService.instance.sendMessage(
          conversationId: conversationId,
          senderId: _currentUserId,
          text: decoded['text'] as String?,
          mediaPath: finalMediaUrl,
          mediaType: type,
          documentName: decoded['documentName'] as String?,
          durationMs: decoded['durationMs'] as int?,
          replyToMessageId: decoded['replyToMessageId']?.toString(),
        );

        // Update UI to show as sent
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == decoded['id']);
            if (idx != -1) {
              _messages[idx] = {
                'id': sent['id'],
                'type': sent['mediaType'] ?? type ?? 'text',
                'text': sent['text'],
                'mediaPath': sent['mediaPath'],
                'documentName': sent['documentName'],
                'durationMs': sent['durationMs'],
        'replyToMessageId': sent['replyToMessageId'] ?? decoded['replyToMessageId'],
        'reactions': (sent['reactions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
                'isSentByMe': true,
                'timestamp': _parseServerDateTimeToLocal(sent['timestamp']),
                'isRead': false,
                'status': 'sent',
              };
            }
          });
          unawaited(_persistMessagesCache());
        }
      } catch (_) {
        try {
          final decoded = jsonDecode(encoded) as Map<String, dynamic>;
          final retryCount = (decoded['retryCount'] as num?)?.toInt() ?? 0;
          if (retryCount + 1 < _maxAutoRetryAttempts) {
            failedMessages.add(
              jsonEncode({...decoded, 'retryCount': retryCount + 1}),
            );
          } else {
            if (mounted) {
              setState(() {
                final idx =
                    _messages.indexWhere((m) => m['id'] == decoded['id']);
                if (idx != -1) {
                  _messages[idx]['status'] = 'failed';
                  _messages[idx]['retryCount'] = retryCount + 1;
                }
              });
            }
          }
        } catch (_) {
          // Keep malformed entries as-is to avoid data loss.
          failedMessages.add(encoded);
        }
      }
    }

    // Update storage: keep only failed messages
    await prefs.setStringList(key, failedMessages);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerChanged);
  _webSocketService?.messageNotifier.removeListener(_handleWsMessageUpdate);
  _webSocketService?.isConnectedNotifier.removeListener(_handleWsConnectionChanged);
  _webSocketService?.deliveryReceiptNotifier
      .removeListener(_handleWsDeliveryReceiptUpdate);
  _webSocketService?.reactionNotifier.removeListener(_handleWsReactionUpdate);
  _webSocketService?.presenceNotifier.removeListener(_handleWsPresenceUpdate);
  _webSocketService?.dispose();
    _pendingRetryTimer?.cancel();
    _messageFetchRetryTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _connectivitySub?.cancel();
    _recordTimer?.cancel();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasAttachment = _pendingAttachment != null;

    if (!hasText && !hasAttachment) return;

    final text = hasText ? _messageController.text.trim() : null;

    if (hasAttachment) {
      final type = _pendingAttachmentType ?? 'file';
      final path = _pendingAttachment!.path;
      final duration = _pendingAudioDurationMs;

      setState(() {
        _pendingAttachment = null;
        _pendingAttachmentType = null;
        _pendingAudioDurationMs = null;
      });
      _messageController.clear();
      HapticFeedback.lightImpact();

      await _sendAttachmentMessage(
        type: type,
        text: text ?? (type == 'audio' ? '[Voice note]' : type == 'video' ? '[Video]' : type == 'image' ? '[Photo]' : null),
        mediaPath: path,
        durationMs: duration,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }

    final localMsg = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'text',
      'text': text,
      'mediaPath': null,
      'documentName': null,
      'durationMs': null,
      'replyToMessageId': _replyToMessageId,
      'reactions': const <String, String>{},
      'isSentByMe': true,
      'timestamp': DateTime.now(),
      'isRead': false,
      'status': _isOnline ? 'sending' : 'pending',
    };

    setState(() {
      _messages.add(localMsg);
    });

    _messageController.clear();
    HapticFeedback.lightImpact();

    // Send to service
    if (!_isOnline) {
      await _queuePendingMessage(localMsg);
      _clearReplyTarget();
      return;
    }

    final convId = await _ensureConversationId();
    if (convId == null) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localMsg['id']);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this conversation right now')),
      );
      return;
    }

    unawaited(_ensureWebSocketForMessaging());

    Future<Map<String, dynamic>> sendFuture() {
      return ConversationService.instance.sendMessage(
        conversationId: convId,
        senderId: _currentUserId,
        text: text,
        replyToMessageId: _replyToMessageId,
      );
    }

    sendFuture().then((sent) {
      // replace optimistic message id with real id and keep isRead false
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localMsg['id']);
        if (idx != -1) {
          _messages[idx] = {
            'id': sent['id'],
            'type': sent['mediaType'] ?? 'text',
            'text': sent['text'] ?? '',
            'mediaPath': sent['mediaPath'],
            'documentName': sent['documentName'],
            'durationMs': sent['durationMs'],
            'replyToMessageId': sent['replyToMessageId'] ?? localMsg['replyToMessageId'],
            'reactions': (sent['reactions'] as Map?)
                    ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
                const <String, String>{},
            'isSentByMe': true,
            'timestamp': _parseServerDateTimeToLocal(sent['timestamp']),
            'isRead': false,
            'status': 'sent',
          };
        }
      });
      _clearReplyTarget();
      unawaited(_removePendingMessageById(localMsg['id'] as String));
      unawaited(_persistMessagesCache());

      if (!kReleaseMode) {
        final serverId = sent['id']?.toString() ?? '';
        debugPrint(
          '[CHAT-VERIFY] send success id=$serverId conv=${_existingConversationId ?? 'pending'}',
        );
        unawaited(() async {
          final persisted = await _confirmMessageStored(serverId);
          debugPrint(
            '[CHAT-VERIFY] persisted=$persisted id=$serverId conv=${_existingConversationId ?? 'pending'}',
          );
        }());
      }
    }).catchError((_) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localMsg['id']);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
      unawaited(_queuePendingMessage(localMsg));
      _clearReplyTarget();
      unawaited(_persistMessagesCache());
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    var difference = now.difference(timestamp);
    if (difference.isNegative) {
      difference = Duration.zero;
    }

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  String _formatLastSeen(DateTime? value) {
    if (value == null) return 'Offline';
    return 'Last seen ${_formatTimestamp(value)}';
  }

  Map<String, dynamic>? _findMessageById(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final message in _messages) {
      if ((message['id']?.toString() ?? '') == id) {
        return message;
      }
    }
    return null;
  }

  String _messagePreview(Map<String, dynamic> message) {
    final text = (message['text']?.toString() ?? '').trim();
    if (text.isNotEmpty) return text;

    final type = (message['type']?.toString() ?? 'text').toLowerCase();
    switch (type) {
      case 'image':
        return '[Photo]';
      case 'video':
        return '[Video]';
      case 'audio':
        return '[Voice note]';
      case 'document':
      case 'file':
        return '[Document]';
      default:
        return '[Message]';
    }
  }

  void _setReplyTarget(Map<String, dynamic> message) {
    setState(() {
      _replyToMessageId = message['id']?.toString();
      _replyPreviewText = _messagePreview(message);
    });
  }

  void _clearReplyTarget() {
    if (!mounted) return;
    setState(() {
      _replyToMessageId = null;
      _replyPreviewText = null;
    });
  }

  Future<void> _togglePinMessage(Map<String, dynamic> message) async {
    final id = message['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() {
      if (_pinnedMessageId == id) {
        _pinnedMessageId = null;
      } else {
        _pinnedMessageId = id;
      }
    });
    await _persistPinnedMessage();
  }

  Future<void> _deleteMessageAction(Map<String, dynamic> message) async {
    final id = message['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final convId = _existingConversationId;
    if (convId != null && !id.startsWith('local_')) {
      await MessageService.deleteMessage(convId, id);
    }

    setState(() {
      _messages.removeWhere((m) => (m['id']?.toString() ?? '') == id);
      if (_pinnedMessageId == id) {
        _pinnedMessageId = null;
      }
      if (_replyToMessageId == id) {
        _replyToMessageId = null;
        _replyPreviewText = null;
      }
    });

    await _removePendingMessageById(id);
    await _persistMessagesCache();
    await _persistPinnedMessage();
  }

  Future<void> _reactToMessage(Map<String, dynamic> message, String emoji) async {
    final id = message['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final existing = (message['reactions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        <String, String>{};
    if (emoji.trim().isEmpty) {
      existing.remove(_currentUserId);
    } else {
      existing[_currentUserId] = emoji;
    }

    setState(() {
      final idx = _messages.indexWhere((m) => (m['id']?.toString() ?? '') == id);
      if (idx != -1) {
        _messages[idx]['reactions'] = existing;
      }
    });
    unawaited(_persistMessagesCache());

    if (_webSocketService?.isConnected == true) {
      _webSocketService?.sendReaction(messageId: id, emoji: emoji);
    }
  }

  Future<void> _showReactionPicker(Map<String, dynamic> message) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        const emojis = ['👍', '❤️', '😂', '🔥', '😮', '😢', '🙏'];
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'React to message',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final emoji in emojis)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).pop(emoji),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(''),
                      icon: const Icon(Icons.close),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _reactToMessage(message, selected);
    }
  }

  Future<void> _forwardMessage(Map<String, dynamic> source) async {
    final users = await MessageService.loadSelectableUsers(size: 120);
    if (!mounted) return;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available for forwarding yet')),
      );
      return;
    }

    final selectedUsers = await _showUserMultiSelectDialog(
      title: 'Forward to...',
      confirmLabel: 'Forward',
      users: users,
    );
    if (selectedUsers == null || selectedUsers.isEmpty) return;

    final usersById = {
      for (final user in users) user.id: user,
    };

    final currentConvId = _existingConversationId;
    final content = _messagePreview(source);
    var forwardedCount = 0;
    for (final userId in selectedUsers.map((user) => user.id)) {
      final user = usersById[userId];
      if (user == null) continue;

      final resolvedConversation =
          await ConversationService.instance.getOrCreateConversation(
        targetUserId: userId,
        targetName: user.name,
        targetAvatar: user.avatar,
      );

      final targetConversationId =
          resolvedConversation['id']?.toString().trim() ?? '';
      if (targetConversationId.isEmpty || targetConversationId == currentConvId) {
        continue;
      }

      await ConversationService.instance.sendMessage(
        conversationId: targetConversationId,
        senderId: _currentUserId,
        text: content,
      );
      forwardedCount++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forwarded to $forwardedCount user(s)')),
    );
  }

  bool get _isGroupConversation => widget.conversation['isGroup'] == true;

  Set<String> _knownConversationParticipantIds() {
    final ids = <String>{};
    final rawParticipants = widget.conversation['participants'];
    if (rawParticipants is! List) return ids;

    for (final item in rawParticipants) {
      if (item is Map) {
        final id = item['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
    }

    return ids;
  }

  Future<List<UserModel>?> _showUserMultiSelectDialog({
    required String title,
    required String confirmLabel,
    required List<UserModel> users,
    Set<String>? initiallySelectedIds,
    int minimumSelection = 1,
  }) async {
    final selectedIds = {...?initiallySelectedIds};
    final queryController = TextEditingController();
    String query = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final filteredUsers = MessageService.filterUsersByQuery(users, query)
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: queryController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, username, or id...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setLocalState(() {
                          query = value.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: filteredUsers.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('No users match your search'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final userId = user.id.trim();
                                final checked = selectedIds.contains(userId);
                                return CheckboxListTile(
                                  value: checked,
                                  title: Text(user.name),
                                  subtitle: Text(userId),
                                  secondary: CircleAvatar(
                                    backgroundImage: user.avatar.trim().isNotEmpty
                                        ? NetworkImage(user.avatar)
                                        : null,
                                    child: user.avatar.trim().isNotEmpty
                                        ? null
                                        : const Icon(Icons.person),
                                  ),
                                  onChanged: (value) {
                                    setLocalState(() {
                                      if (value == true) {
                                        selectedIds.add(userId);
                                      } else {
                                        selectedIds.remove(userId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedIds.length < minimumSelection
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );

    queryController.dispose();
    if (confirmed != true) return null;

    return users.where((user) => selectedIds.contains(user.id.trim())).toList();
  }

  Future<void> _handleGroupAction() async {
    if (_isGroupConversation) {
      await _addMembersToCurrentGroup();
    } else {
      await _createGroupRoom();
    }
  }

  Future<void> _createGroupRoom() async {
    final users = await MessageService.loadSelectableUsers(size: 140);
    if (!mounted) return;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to create a room')),
      );
      return;
    }

    final preselected = <String>{};
    if (_peerUserId.trim().isNotEmpty) {
      preselected.add(_peerUserId.trim());
    }

    final selected = await _showUserMultiSelectDialog(
      title: 'Create group room',
      confirmLabel: 'Create',
      users: users,
      initiallySelectedIds: preselected,
      minimumSelection: 2,
    );
    if (selected == null || selected.length < 2) {
      return;
    }

    final participantIds = selected.map((user) => user.id.trim()).toList();
    final created = await MessageService.createConversation(
      name: 'Group chat',
      participantIds: participantIds,
      isGroup: true,
    );

    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group room')), 
      );
      return;
    }

    final opened = await ConversationService.instance.getConversationById(created.id);
    final conversationMap = (opened != null)
        ? {
            ...opened,
            'isGroup': true,
          }
        : {
      'id': created.id,
      'name': created.name.isNotEmpty ? created.name : 'Group chat',
      'avatar': '',
      'isGroup': true,
      'participants': created.participants.map((p) => p.toJson()).toList(),
    };

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(conversation: conversationMap),
      ),
    );
  }

  Future<void> _addMembersToCurrentGroup() async {
    final conversationId = _existingConversationId;
    if (conversationId == null || conversationId.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open this group first, then try again')),
      );
      return;
    }

    final existingMembers = _knownConversationParticipantIds();
    final users = (await MessageService.loadSelectableUsers(size: 140))
        .where((user) => !existingMembers.contains(user.id.trim()))
        .toList(growable: false);

    if (!mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No additional users available to add')),
      );
      return;
    }

    final selected = await _showUserMultiSelectDialog(
      title: 'Add members',
      confirmLabel: 'Add',
      users: users,
      minimumSelection: 1,
    );
    if (selected == null || selected.isEmpty) return;

    final added = await MessageService.addParticipantsDefensive(
      conversationId: conversationId,
      userIds: selected.map((user) => user.id).toList(),
    );

    if (!mounted) return;
    if (added <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add members right now')),
      );
      return;
    }

    final rawParticipants = widget.conversation['participants'];
    final updatedParticipants = <Map<String, dynamic>>[];
    if (rawParticipants is List) {
      for (final item in rawParticipants) {
        if (item is Map) {
          updatedParticipants.add(item.cast<String, dynamic>());
        }
      }
    }
    for (final user in selected.take(added)) {
      updatedParticipants.add({
        'id': user.id,
        'name': user.name,
        'avatar': user.avatar,
        'isOnline': user.isOnline,
        'lastSeenAt': user.lastSeenAt?.toUtc().toIso8601String(),
      });
    }
    widget.conversation['participants'] = updatedParticipants;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $added member(s)')),
    );
  }

  Future<void> _showMessageActions(Map<String, dynamic> message) async {
    final pinned = _pinnedMessageId == (message['id']?.toString() ?? '');
    final mediaUrl = message['mediaPath']?.toString();
    final isNetworkMedia = mediaUrl != null && mediaUrl.startsWith('http');
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () => Navigator.of(context).pop('reply'),
              ),
              if (isNetworkMedia)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download media'),
                  onTap: () => Navigator.of(context).pop('download'),
                ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () => Navigator.of(context).pop('forward'),
              ),
              ListTile(
                leading: Icon(pinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(pinned ? 'Unpin message' : 'Pin message'),
                onTap: () => Navigator.of(context).pop('pin'),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('React'),
                onTap: () => Navigator.of(context).pop('react'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete message', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'reply':
        _setReplyTarget(message);
        break;
      case 'forward':
        await _forwardMessage(message);
        break;
      case 'download':
        final url = message['mediaPath']?.toString();
        if (url != null) {
          final ext = url.split('.').last.split('?').first;
          final name = 'ispilo_chat_media_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'bin' : ext}';
          await MediaDownloadService.downloadFile(url, name, context);
        }
        break;
      case 'pin':
        await _togglePinMessage(message);
        break;
      case 'react':
        await _showReactionPicker(message);
        break;
      case 'delete':
        await _deleteMessageAction(message);
        break;
      default:
        break;
    }
  }

  DateTime _parseServerDateTimeToLocal(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return DateTime.now();

    var normalized = value;
    final hasTimezone = normalized.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(normalized);

    if (!hasTimezone) {
      normalized = '${normalized}Z';
    }

    final parsed = DateTime.tryParse(normalized);
    return parsed?.toLocal() ?? DateTime.now();
  }

  Color _sentBubbleColor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF2E7D32).withValues(alpha: 0.38)
        : const Color(0xFFE6F4EA);
  }

  Color _sentContentColor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return isDark ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20);
  }

  Color _sentMetaColor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
  }

  Color _sentTickColor(ColorScheme colorScheme, {required bool isRead, String? status}) {
    final isDark = colorScheme.brightness == Brightness.dark;
    if (isRead) {
      return isDark ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32);
    }
    if (status == 'delivered' || status == 'read') {
      return isDark ? const Color(0xFF81C784) : const Color(0xFF43A047);
    }
    return isDark ? const Color(0xFFA5D6A7) : const Color(0xFF66BB6A);
  }

  Widget _buildMessageContent(
      Map<String, dynamic> message, bool isSentByMe, ColorScheme colorScheme) {
    final type = (message['type'] as String?) ?? 'text';
    switch (type) {
      case 'image':
        final path = message['mediaPath'] as String?;
        if (path != null && File(path).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              width: 60.w,
              fit: BoxFit.cover,
            ),
          );
        }
        return _buildAttachmentPlaceholder(
          icon: Icons.broken_image,
          label: 'Image unavailable',
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'audio':
        final durationMs = message['durationMs'] as int?;
        final durationLabel = durationMs != null
            ? Duration(milliseconds: durationMs).toString().split('.').first
            : 'Voice note';
        return _buildAttachmentPlaceholder(
          icon: Icons.mic,
          label: durationLabel,
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'document':
        final name = message['documentName'] as String? ?? 'Document';
        return _buildAttachmentPlaceholder(
          icon: Icons.insert_drive_file,
          label: name,
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'text':
      default:
        final text = (message['text'] as String?) ?? '';
        return Text(
          text.isEmpty ? '[Unsupported message]' : text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isSentByMe ? _sentContentColor(colorScheme) : colorScheme.onSurface,
          ),
        );
    }
  }

  Widget _buildAttachmentPlaceholder({
    required IconData icon,
    required String label,
    required bool isSentByMe,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isSentByMe ? _sentContentColor(colorScheme) : colorScheme.onSurface,
        ),
        SizedBox(width: 2.w),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isSentByMe ? _sentContentColor(colorScheme) : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _ensurePermissions(List<Permission> permissions,
      {String? rationale}) async {
    bool allGranted = true;
    for (final permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
      }
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    if (!allGranted && rationale != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rationale)),
      );
    }

    return allGranted;
  }

  Future<String> _persistLocalFile(File source, {String? preferredName}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = source.path.split('.').last;
    final sanitizedExt = ext.isEmpty ? 'bin' : ext;
    final fileName = preferredName ??
        'chat_${DateTime.now().millisecondsSinceEpoch}.$sanitizedExt';
    final targetPath = '${docsDir.path}/$fileName';
    final savedFile = await source.copy(targetPath);
    return savedFile.path;
  }

  Future<void> _handleCameraTap() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Attach Media',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureMedia(ImageSource.camera, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record a Video'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureMedia(ImageSource.camera, true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureMedia(ImageSource.gallery, false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureMedia(ImageSource source, bool isVideo) async {
    bool hasPermissions = true;
    if (source == ImageSource.camera) {
      hasPermissions = await _ensurePermissions(
        [Permission.camera, Permission.microphone],
        rationale: 'Permissions are required to capture media.',
      );
    }
    if (!hasPermissions) return;

    XFile? capture;
    if (isVideo) {
      capture = await _imagePicker.pickVideo(source: source);
    } else {
      capture = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
    }
    
    if (capture == null) return;

    final savedPath = await _persistLocalFile(File(capture.path));
    setState(() {
      _pendingAttachment = File(savedPath);
      _pendingAttachmentType = isVideo ? 'video' : 'image';
      _pendingAudioDurationMs = null;
    });
  }

  Future<void> _sendAttachmentMessage({
    required String type,
    String? text,
    String? mediaPath,
    String? documentName,
    int? durationMs,
  }) async {
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final localMessage = {
      'id': localId,
      'type': type,
      'text': text,
      'mediaPath': mediaPath,
      'documentName': documentName,
      'durationMs': durationMs,
      'replyToMessageId': _replyToMessageId,
      'reactions': const <String, String>{},
      'isSentByMe': true,
      'timestamp': DateTime.now(),
      'isRead': false,
      'status': _isOnline ? 'sending' : 'pending',
    };

    setState(() {
      _messages.add(localMessage);
    });

    if (!_isOnline) {
      await _queuePendingMessage(localMessage);
      _clearReplyTarget();
      return;
    }

    final convId = await _ensureConversationId();
    if (convId == null) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this conversation right now')),
      );
      return;
    }

    unawaited(_ensureWebSocketForMessaging());

    try {
      String? finalMediaUrl = mediaPath;
      if (mediaPath != null && !mediaPath.startsWith('http')) {
        final isVideo = type == 'video';
        final uploadedUrl = await CloudinaryService.uploadFile(mediaPath, isVideo: isVideo, resourceType: 'auto');
        if (uploadedUrl != null) {
          finalMediaUrl = uploadedUrl;
        }
      }

      final sent = await ConversationService.instance.sendMessage(
        conversationId: convId,
        senderId: _currentUserId,
        text: text,
        mediaPath: finalMediaUrl,
        mediaType: type,
        documentName: documentName,
        durationMs: durationMs,
        replyToMessageId: _replyToMessageId,
      );

      if (!mounted) return;

      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) {
          _messages[idx] = {
            'id': sent['id'],
            'type': sent['mediaType'] ?? type,
            'text': sent['text'],
            'mediaPath': sent['mediaPath'] ?? mediaPath,
            'documentName': sent['documentName'] ?? documentName,
            'durationMs': sent['durationMs'] ?? durationMs,
            'replyToMessageId': sent['replyToMessageId'] ?? localMessage['replyToMessageId'],
            'reactions': (sent['reactions'] as Map?)
                    ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
                const <String, String>{},
            'isSentByMe': true,
            'timestamp': _parseServerDateTimeToLocal(sent['timestamp']),
            'isRead': false,
            'status': 'sent',
          };
        }
      });
      _clearReplyTarget();

      if (!kReleaseMode) {
        final serverId = sent['id']?.toString() ?? '';
        debugPrint(
          '[CHAT-VERIFY] send success id=$serverId conv=${_existingConversationId ?? 'pending'}',
        );
        unawaited(() async {
          final persisted = await _confirmMessageStored(serverId);
          debugPrint(
            '[CHAT-VERIFY] persisted=$persisted id=$serverId conv=${_existingConversationId ?? 'pending'}',
          );
        }());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
      await _queuePendingMessage(localMessage);
      unawaited(_persistMessagesCache());
    }
  }

  Future<void> _queuePendingMessage(Map<String, dynamic> message) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

  final key = _pendingMessagesKey;
    final existing = prefs.getStringList(key) ?? [];
    final messageId = message['id']?.toString();
    final deduped = <String>[];
    for (final entry in existing) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        if (messageId != null && map['id']?.toString() == messageId) {
          continue;
        }
      } catch (_) {
        // Keep unparseable entries.
      }
      deduped.add(entry);
    }
    final encoded = jsonEncode({
      'id': message['id'],
      'type': message['type'],
      'text': message['text'],
      'mediaPath': message['mediaPath'],
      'documentName': message['documentName'],
      'durationMs': message['durationMs'],
      'replyToMessageId': message['replyToMessageId'],
      'retryCount': (message['retryCount'] as num?)?.toInt() ?? 0,
      'timestamp': (message['timestamp'] as DateTime).toIso8601String(),
    });
    deduped.add(encoded);
    await prefs.setStringList(key, deduped);
  }

  Future<void> _handleVoiceRecordStart() async {
    final granted = await _ensurePermissions(
      [Permission.microphone],
      rationale: 'Microphone access is required to record voice notes.',
    );
    if (!granted) return;

    if (_isRecording) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${docsDir.path}/$fileName';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _handleVoiceRecordStop() async {
    if (!_isRecording) return;

    _recordTimer?.cancel();
    _recordTimer = null;

    final path = await _audioRecorder.stop();
    final duration = _recordDuration;

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;

      if (path != null && File(path).existsSync()) {
        _pendingAttachment = File(path);
        _pendingAttachmentType = 'audio';
        _pendingAudioDurationMs = duration.inMilliseconds;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF0E4D45)
        : const Color(0xFF075E54);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appBarGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openConversationProfile,
          child: Row(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: CustomImageWidget(
                              imageUrl: _peerAvatar,
                      width: 10.w,
                      height: 10.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_peerIsOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 2.5.w,
                        height: 2.5.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        //  Display the peer's name, truncating with an ellipsis if it's too long
                         Flexible(
                           child: Text(
                        _peerName,
                            maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                           color: Colors.white,
                           ),
                          ),
                         ),
                        if (_peerIsVerified) ...[
                          SizedBox(width: 1.w),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF25D366),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _peerIsOnline ? 'Online' : _formatLastSeen(_peerLastSeenAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    if (!kReleaseMode)
                      Text(
                       // 'peer=$_peerUserId 
                      // 'conv=${_existingConversationId ?? 'pending'}',
                      'pending',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadConversationMessages();
            },
            tooltip: 'Refresh chats',
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _handleGroupAction,
            tooltip: _isGroupConversation ? 'Add members' : 'Create group room',
            icon: Icon(
              _isGroupConversation ? Icons.group_add : Icons.groups,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMessageStatusLegend(colorScheme),
          if (_pinnedMessageId != null && _findMessageById(_pinnedMessageId) != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(3.w, 0.8.h, 3.w, 0.2.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.9.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: colorScheme.primary),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Pinned: ${_messagePreview(_findMessageById(_pinnedMessageId)!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        _pinnedMessageId = null;
                      });
                      await _persistPinnedMessage();
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                image: DecorationImage(
                  image: const NetworkImage(
                      'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(3.w),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isSentByMe = message['isSentByMe'];
                  final replyToId = message['replyToMessageId']?.toString();
                  final repliedMessage = _findMessageById(replyToId);
                  final reactionsMap = (message['reactions'] as Map?)
                          ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
                      const <String, String>{};
                  final reactionCounts = <String, int>{};
                  for (final emoji in reactionsMap.values) {
                    reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
                  }

                  return GestureDetector(
                    onLongPress: () => _showMessageActions(message),
                    onTap: () {
                      if (kIsWeb) {
                        _showMessageActions(message);
                      }
                    },
                    onDoubleTap: () => _setReplyTarget(message),
                    onSecondaryTap: () => _showMessageActions(message),
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 250) {
                        _setReplyTarget(message);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                      mainAxisAlignment: isSentByMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isSentByMe) ...[
                          ClipOval(
                            child: CustomImageWidget(
                              imageUrl: _peerAvatar,
                              width: 8.w,
                              height: 8.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 2.w),
                        ],
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSentByMe
                                  ? _sentBubbleColor(colorScheme)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (repliedMessage != null)
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(bottom: 0.7.h),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSentByMe
                                          ? _sentMetaColor(colorScheme).withValues(alpha: 0.18)
                                          : colorScheme.onSurface.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _messagePreview(repliedMessage),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isSentByMe
                                            ? _sentContentColor(colorScheme)
                                            : colorScheme.onSurface.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                _buildMessageContent(
                                    message, isSentByMe, colorScheme),
                                if (reactionCounts.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 0.7.h),
                                    child: Wrap(
                                      spacing: 1.w,
                                      children: reactionCounts.entries
                                          .map(
                                            (entry) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.surface.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${entry.key} ${entry.value}',
                                                style: GoogleFonts.inter(fontSize: 11),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                SizedBox(height: 0.5.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(message['timestamp']),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSentByMe
                      ? _sentMetaColor(colorScheme)
                                                .withValues(alpha: 0.7)
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    if (message['status'] == 'pending') ...[
                                      SizedBox(width: 1.w),
                                      GestureDetector(
                                        onTap: isSentByMe
                                            ? () => _retryMessageById(
                                                  message['id']?.toString() ?? '',
                                                )
                                            : null,
                                        child: Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: isSentByMe
                        ? _sentMetaColor(colorScheme)
                                                  .withValues(alpha: 0.7)
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ] else if (message['status'] ==
                                        'failed') ...[
                                      SizedBox(width: 2.w),
                                      GestureDetector(
                                        onTap: isSentByMe
                                            ? () => _retryMessageById(
                                                  message['id']?.toString() ?? '',
                                                )
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.refresh, size: 12, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Retry', style: TextStyle(fontSize: 10, color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      GestureDetector(
                                        onTap: isSentByMe
                                            ? () async {
                                                final id = message['id']?.toString() ?? '';
                                                setState(() {
                                                  _messages.removeWhere((m) => m['id']?.toString() == id);
                                                });
                                                await _removePendingMessageById(id);
                                                await _persistMessagesCache();
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                                                                       color: Colors.black.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.delete, size: 12, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Delete', style: TextStyle(fontSize: 10, color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isSentByMe && message['status'] != 'failed' && message['status'] != 'pending') ...[
                                      SizedBox(width: 1.w),
                                      Icon(
                                        message['isRead']
                                            ? Icons.done_all
                                            : ((message['status'] == 'delivered' ||
                                                    message['status'] == 'read')
                                                ? Icons.done_all
                                                : Icons.done),
                                        size: 14,
                                        color: _sentTickColor(
                                          colorScheme,
                                          isRead: message['isRead'] == true,
                                          status: message['status']?.toString(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSentByMe) ...[
                          SizedBox(width: 2.w),
                          ClipOval(
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ));
                },
              ),
            ),
          ),

          // Message Input
          if (_pendingAttachment != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_pendingAttachmentType == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _pendingAttachment!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_pendingAttachmentType == 'video')
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.videocam, size: 30, color: Colors.black54),
                    )
                  else if (_pendingAttachmentType == 'audio')
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.mic, size: 30, color: Color(0xFF1877F2)),
                    ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pendingAttachmentType == 'image' ? 'Photo attached' :
                          _pendingAttachmentType == 'video' ? 'Video attached' :
                          'Voice note (${Duration(milliseconds: _pendingAudioDurationMs ?? 0).toString().split('.').first})',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ready to send... add a caption below',
                          style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    onPressed: () {
                      setState(() {
                        _pendingAttachment = null;
                        _pendingAttachmentType = null;
                        _pendingAudioDurationMs = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyToMessageId != null) ...[
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 0.8.h),
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: colorScheme.primary),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              _replyPreviewText ?? 'Replying...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _clearReplyTarget,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                  // Camera Icon
                  IconButton(
                    onPressed: _handleCameraTap,
                    icon: Icon(
                      Icons.camera_alt,
                      color: const Color(0xFF1877F2),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  // Voice Note Icon (when not recording)
                  if (!_isRecording)
                    GestureDetector(
                      onLongPress: _handleVoiceRecordStart,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: Icon(
                          Icons.mic,
                          color: const Color(0xFF1877F2),
                          size: 24,
                        ),
                      ),
                    ),
                  // Recording indicator (when recording)
                  if (_isRecording)
                    GestureDetector(
                      onTap: _handleVoiceRecordStop,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  // Recording duration display
                  if (_isRecording) ...[
                    SizedBox(width: 2.w),
                    Text(
                      '${_recordDuration.inMinutes}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Send button (only shows when there's text or pending attachment)
                  if (_messageController.text.trim().isNotEmpty || _pendingAttachment != null)
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusLegend(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.6),
      child: Wrap(
        spacing: 3.w,
        runSpacing: 0.2.h,
        children: [
          _buildLegendItem(
            icon: Icons.done,
            label: 'Sent',
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            textColor: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          _buildLegendItem(
            icon: Icons.done_all,
            label: 'Delivered',
            color: colorScheme.onSurface.withValues(alpha: 0.85),
            textColor: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          _buildLegendItem(
            icon: Icons.done_all,
            label: 'Read',
            color: const Color(0xFF1877F2),
            textColor: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 0.8.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: textColor),
        ),
      ],
    );
  }
}
