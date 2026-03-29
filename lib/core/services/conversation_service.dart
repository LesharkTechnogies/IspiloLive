import 'dart:async';
import '../unread_message_service.dart';

/// Mock conversation service — in a real app, this would query your backend
/// for an existing conversation between current user and target seller, or create one.
class ConversationService {
  ConversationService._internal();

  static final ConversationService instance = ConversationService._internal();

  // Mock storage: conversationId -> map
  final Map<String, Map<String, dynamic>> _conversations = {};
  // Mock messages storage: conversationId -> list of messages
  final Map<String, List<Map<String, dynamic>>> _messages = {};

  Future<Map<String, dynamic>> getOrCreateConversation({
    required String sellerId,
    required String sellerName,
    required String sellerAvatar,
  }) async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final convId = 'conv_$sellerId';
    _conversations.putIfAbsent(
        convId,
        () => {
              'id': convId,
              'name': sellerName,
              'avatar': sellerAvatar,
              'sellerId': sellerId,
              'isOnline': false,
              'isVerified': false,
              'unreadCount': 0,
            });

    _messages.putIfAbsent(convId, () => <Map<String, dynamic>>[]);

    return _conversations[convId]!;
  }

  /// Fetch messages for a conversation (most recent first)
  Future<List<Map<String, dynamic>>> fetchMessages(String conversationId,
      {int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final msgs = _messages[conversationId] ?? <Map<String, dynamic>>[];
    // return a copy with the most recent first, limited
    final result = List<Map<String, dynamic>>.from(msgs.reversed);
    if (result.length > limit) return result.sublist(0, limit);
    return result;
  }

  /// Send a message into a conversation; increments unread counters for recipients
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    String? text,
    String? mediaPath,
    String? mediaType,
    String? documentName,
    int? durationMs,
  }) async {
    if ((text == null || text.trim().isEmpty) &&
        (mediaPath == null || mediaPath.isEmpty)) {
      throw ArgumentError('Either text or mediaPath must be provided');
    }

    await Future.delayed(const Duration(milliseconds: 120));

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final resolvedType = mediaType ?? (text != null ? 'text' : null);
    final message = {
      'id': msgId,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'mediaPath': mediaPath,
      'mediaType': resolvedType,
      'documentName': documentName,
      'durationMs': durationMs,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    _messages.putIfAbsent(conversationId, () => <Map<String, dynamic>>[]);
    _messages[conversationId]!.add(message);

    // Update conversation lastMessage and increment unread
    final conv = _conversations[conversationId];
    if (conv != null) {
      conv['lastMessage'] = message;
      conv['unreadCount'] = (conv['unreadCount'] as int? ?? 0) + 1;
      // Increment global unread counter as a simple simulation
      UnreadMessageService.instance.increment(1);
    }

    return message;
  }

  /// Mark a conversation as read for a user: decrement global unread by this conv's unreadCount and clear it
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final conv = _conversations[conversationId];
    if (conv == null) return;
    final int convUnread = conv['unreadCount'] as int? ?? 0;
    if (convUnread > 0) {
      // decrement global unread (ensure non-negative)
      final remaining = UnreadMessageService.instance.count - convUnread;
      UnreadMessageService.instance.count = remaining < 0 ? 0 : remaining;
      conv['unreadCount'] = 0;
    }
  }

  /// Return conversation by id
  Future<Map<String, dynamic>?> getConversationById(
      String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _conversations[conversationId];
  }
}
