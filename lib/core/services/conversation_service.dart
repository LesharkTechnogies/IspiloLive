import 'package:ispilo/core/services/message_service.dart' as message_api;
import 'package:ispilo/model/message_model.dart' show ConversationModel, MessageModel;

/// Production conversation service adapter used by chat/product UI.
///
/// It wraps `MessageService` so existing screens can keep their current
/// method calls while using backend data (not mock storage).
class ConversationService {
  ConversationService._internal();

  static final ConversationService instance = ConversationService._internal();

  Future<Map<String, dynamic>> getOrCreateConversation({
    required String sellerId,
    required String sellerName,
    required String sellerAvatar,
  }) async {
    // Backend contract for "find existing private conversation" is not exposed
    // here, so we create a private conversation with seller participant and
    // rely on backend deduplication policy if available.
  final created = await message_api.MessageService.createConversation(
      name: sellerName,
      participantIds: [sellerId],
      isGroup: false,
    );

    if (created != null) {
      return _conversationToUiMap(created, fallbackAvatar: sellerAvatar);
    }

    // Safe fallback map shape expected by ChatPage/app routes.
    return {
      'id': 'conv_$sellerId',
      'name': sellerName,
      'avatar': sellerAvatar,
      'sellerId': sellerId,
      'isOnline': false,
      'isVerified': false,
      'unreadCount': 0,
      'encryptionKey': null,
    };
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
  }) async {
    final messageType = _toMessageType(mediaType);

  final sent = await message_api.MessageService.sendMessage(
      conversationId: conversationId,
      content: text ?? '',
      messageType: messageType,
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
      'userId': conversation.id,
      'name': conversation.name.isNotEmpty
          ? conversation.name
          : (firstParticipant?.name ?? 'Conversation'),
      'avatar': firstParticipant?.avatar ?? fallbackAvatar,
      'lastMessage': conversation.lastMessage,
      'timestamp': conversation.lastMessageTime.toLocal().toString(),
      'isOnline': firstParticipant?.isOnline ?? false,
      'unreadCount': conversation.unreadCount,
      'isVerified': false,
      'isGroup': conversation.isGroup,
      'encryptionKey': conversation.encryptionKey,
      'participants': conversation.participants.map((p) => p.toJson()).toList(),
    };
  }
}
