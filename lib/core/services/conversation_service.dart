import 'package:ispilo/core/services/message_service.dart' as message_api;
import 'package:ispilo/model/message_model.dart' show ConversationModel, MessageModel;

/// Production conversation service adapter used by chat/product UI.
///
/// It wraps `MessageService` so existing screens can keep their current
/// method calls while using backend data (not mock storage).
class ConversationService {
  ConversationService._internal();

  static final ConversationService instance = ConversationService._internal();
  static final Map<String, Future<Map<String, dynamic>>> _inFlightDirectConversations =
      <String, Future<Map<String, dynamic>>>{};

  Future<Map<String, dynamic>> getOrCreateConversation({
    required String targetUserId,
    required String targetName,
    required String targetAvatar,
  }) async {
    final key = targetUserId.trim();
    if (key.isEmpty) {
      throw Exception('Unable to create conversation with this user right now');
    }

    final existing = _inFlightDirectConversations[key];
    if (existing != null) {
      return existing;
    }

    final operation = _getOrCreateConversationInternal(
      targetUserId: targetUserId,
      targetName: targetName,
      targetAvatar: targetAvatar,
    );

    _inFlightDirectConversations[key] = operation;
    try {
      return await operation;
    } finally {
      _inFlightDirectConversations.remove(key);
    }
  }

  Future<Map<String, dynamic>> _getOrCreateConversationInternal({
    required String targetUserId,
    required String targetName,
    required String targetAvatar,
  }) async {
    final found = await message_api.MessageService.findDirectConversation(
      targetUserId: targetUserId,
    );
    if (found != null) {
      return _conversationToUiMap(found, fallbackAvatar: targetAvatar);
    }

    final created = await message_api.MessageService.createConversation(
      name: targetName,
      participantIds: [targetUserId],
      isGroup: false,
    );

    if (created != null) {
      return _conversationToUiMap(created, fallbackAvatar: targetAvatar);
    }

    throw Exception('Unable to create conversation with this user right now');
  }

  /// Fetch messages for a conversation (most recent first)
  Future<List<Map<String, dynamic>>> fetchMessages(
    String conversationId, {
    int limit = 50,
  }) async {
  final messages = await message_api.MessageService.getMessages(
      conversationId,
      size: limit,
    );

    return messages.map(_messageToUiMap).toList();
  }

  /// Send a message into a conversation
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    String? text,
    String? mediaPath,
    String? mediaType,
    String? documentName,
    int? durationMs,
    String? replyToMessageId,
  }) async {
    final messageType = _toMessageType(mediaType);

  final sent = await message_api.MessageService.sendMessage(
      conversationId: conversationId,
      content: text ?? '',
      senderId: senderId,
      messageType: messageType,
      replyToMessageId: replyToMessageId,
    );

    if (sent == null) {
      throw Exception('Failed to send message');
    }

    return {
      ..._messageToUiMap(sent),
      // Keep optional media-related fields for compatibility with current UI.
      'mediaPath': mediaPath,
      'documentName': documentName,
      'durationMs': durationMs,
      'mediaType': mediaType ?? messageType.name,
    };
  }

  Future<void> markConversationRead(String conversationId, String userId) {
    return message_api.MessageService.markConversationAsRead(conversationId);
  }

  Future<Map<String, dynamic>?> getConversationById(String conversationId) async {
  final conversation = await message_api.MessageService.getConversationById(conversationId);
    if (conversation == null) return null;
    return _conversationToUiMap(conversation);
  }

  static message_api.MessageType _toMessageType(String? type) {
    switch ((type ?? 'text').toLowerCase()) {
      case 'image':
        return message_api.MessageType.image;
      case 'video':
        return message_api.MessageType.video;
      case 'file':
      case 'document':
        return message_api.MessageType.file;
      case 'location':
        return message_api.MessageType.location;
      case 'text':
      default:
        return message_api.MessageType.text;
    }
  }

  static Map<String, dynamic> _messageToUiMap(MessageModel message) {
    return {
      'id': message.id,
      'conversationId': message.conversationId,
      'senderId': message.senderId,
      'text': message.content,
      'mediaPath': message.mediaUrl,
      'mediaType': message.type.name,
      'documentName': null,
      'durationMs': null,
      'timestamp': message.timestamp.toUtc().toIso8601String(),
      'isRead': message.isRead,
      'replyToMessageId': message.replyToMessageId,
      'reactions': message.reactions,
    };
  }

  static Map<String, dynamic> _conversationToUiMap(
    ConversationModel conversation, {
    String? fallbackAvatar,
  }) {
    final firstParticipant =
        conversation.participants.isNotEmpty ? conversation.participants.first : null;

    return {
      'id': conversation.id,
      'userId': firstParticipant?.id,
      'name': conversation.name.isNotEmpty
          ? conversation.name
          : (firstParticipant?.name ?? 'Conversation'),
      'avatar': firstParticipant?.avatar ?? fallbackAvatar,
      'lastMessage': conversation.lastMessage,
      'timestamp': conversation.lastMessageTime.toLocal().toString(),
      'isOnline': firstParticipant?.isOnline ?? false,
  'lastSeenAt': firstParticipant?.lastSeenAt?.toUtc().toIso8601String(),
      'unreadCount': conversation.unreadCount,
      'isVerified': false,
      'isGroup': conversation.isGroup,
      'encryptionKey': conversation.encryptionKey,
      'participants': conversation.participants.map((p) => p.toJson()).toList(),
    };
  }
}
