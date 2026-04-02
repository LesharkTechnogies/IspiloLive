import 'package:ispilo/core/services/api_service.dart';
import 'package:ispilo/model/message_model.dart';

/// Repository for messaging API calls
class ConversationRepository {
  static const String _baseEndpoint = '/conversations';

  /// Get user's conversations with pagination
  static Future<List<ConversationModel>> getConversations({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  /// Get conversation by ID
  static Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$conversationId');
      return ConversationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch conversation: $e');
    }
  }

  /// Get conversation messages with pagination
  static Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/$conversationId/messages?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Create new conversation
  static Future<ConversationModel> createConversation({
    required List<String> participantIds,
    String? name,
  }) async {
    try {
      final payload = {
        'participantIds': participantIds,
        if (name != null) 'name': name,
      };

      final response = await ApiService.post(_baseEndpoint, payload);
      return ConversationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Create/find direct conversation with one user
  static Future<ConversationModel> createOrGetDirectConversation({
    required String participantId,
  }) async {
    try {
      final response = await ApiService.post(
        '$_baseEndpoint/direct',
        {'participantId': participantId},
      );
      return ConversationModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      // Fallback for backends that use the generic create endpoint
      final response = await ApiService.post(
        _baseEndpoint,
        {
          'participantIds': [participantId],
          'isGroup': false,
        },
      );
      return ConversationModel.fromJson(response as Map<String, dynamic>);
    }
  }

  /// Send message via REST API (for backup when WebSocket is unavailable)
  static Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? encryptedContent,
    String? encryptionIv,
    String? mediaUrl,
    String? clientMsgId,
  }) async {
    try {
      final payload = {
        'conversationId': conversationId,
        'content': content,
        if (encryptedContent != null) 'encryptedContent': encryptedContent,
        if (encryptionIv != null) 'encryptionIv': encryptionIv,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (clientMsgId != null) 'clientMsgId': clientMsgId,
        'type': 'TEXT',
      };

      final response = await ApiService.post(
        '$_baseEndpoint/$conversationId/messages',
        payload,
      );
      return MessageModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await ApiService.delete('/messages/$messageId');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await ApiService.post(
        '$_baseEndpoint/$conversationId/read',
        {},
      );
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Mark specific message as read
  static Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await ApiService.post(
        '$_baseEndpoint/$conversationId/messages/$messageId/read',
        {},
      );
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Add participant to group conversation
  static Future<void> addParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await ApiService.post(
        '$_baseEndpoint/$conversationId/participants',
        {'userId': userId},
      );
    } catch (e) {
      throw Exception('Failed to add participant: $e');
    }
  }

  /// Remove participant from group conversation
  static Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await ApiService.delete('$_baseEndpoint/$conversationId/participants/$userId');
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  /// Leave conversation
  static Future<void> leaveConversation(String conversationId) async {
    try {
      await ApiService.delete('$_baseEndpoint/$conversationId/leave');
    } catch (e) {
      throw Exception('Failed to leave conversation: $e');
    }
  }

  /// Search in conversation
  static Future<List<MessageModel>> searchInConversation({
    required String conversationId,
    required String keyword,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/$conversationId/search?keyword=$keyword',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  /// Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      await ApiService.delete('$_baseEndpoint/$conversationId');
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
