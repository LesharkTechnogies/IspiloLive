import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:ispilo/model/message_model.dart';

/// Message service for managing conversations and messages
class MessageService {
  static const String _messageCacheKey = 'cached_messages';
  static const String _conversationCacheKey = 'cached_conversations';

  // Stream controllers
  static final StreamController<List<ConversationModel>> _conversationStreamController =
      StreamController<List<ConversationModel>>.broadcast();

  static final StreamController<Map<String, List<MessageModel>>> _messageStreamController =
      StreamController<Map<String, List<MessageModel>>>.broadcast();

  static final StreamController<ConversationModel> _conversationUpdateStreamController =
      StreamController<ConversationModel>.broadcast();

  // Public streams
  static Stream<List<ConversationModel>> get conversationStream => _conversationStreamController.stream;
  static Stream<Map<String, List<MessageModel>>> get messageStream => _messageStreamController.stream;
  static Stream<ConversationModel> get conversationUpdateStream => _conversationUpdateStreamController.stream;

  // Cleanup on app close
  static void dispose() {
    _conversationStreamController.close();
    _messageStreamController.close();
    _conversationUpdateStreamController.close();
  }

  /// Get all conversations for current user
  static Future<List<ConversationModel>> getConversations({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await ApiService.get(
        '/conversations?page=$page&size=$size',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      final conversations = content
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache locally
      await _cacheConversations(conversations);

      // Update stream
      _conversationStreamController.add(conversations);

      return conversations;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      // Return cached data if available
      return await _getCachedConversations();
    }
  }

  /// Get messages for a specific conversation
  static Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await ApiService.get(
        '/conversations/$conversationId/messages?page=$page&size=$size',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      final messages = content
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update stream
      _messageStreamController.add({conversationId: messages});

      return messages;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message
  static Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    String? encryptedContent,
    String? encryptionIv,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final payload = {
        'content': content,
        'type': messageType.toString().split('.').last,
        if (encryptedContent != null) 'encryptedContent': encryptedContent,
        if (encryptionIv != null) 'encryptionIv': encryptionIv,
      };

      final response = await ApiService.post(
        '/conversations/$conversationId/messages',
        payload,
      );

      final message = MessageModel.fromJson(response as Map<String, dynamic>);

      // Refresh conversation
      await getConversations();

      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  /// Create a new conversation
  static Future<ConversationModel?> createConversation({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    try {
      final payload = {
        'name': name,
        'participantIds': participantIds,
        'isGroup': isGroup,
      };

      final response = await ApiService.post(
        '/conversations',
        payload,
      );

      final conversation = ConversationModel.fromJson(response as Map<String, dynamic>);

      // Refresh conversations
      await getConversations();

      return conversation;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Get unread conversations
  static Future<List<ConversationModel>> getUnreadConversations() async {
    try {
      final response = await ApiService.get('/conversations/unread');

      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching unread conversations: $e');
      return [];
    }
  }

  /// Get unread message count
  static Future<int> getUnreadMessageCount() async {
    try {
      final response = await ApiService.get('/conversations/unread-count');
      return response['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error fetching unread message count: $e');
      return 0;
    }
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      await ApiService.post(
        '/conversations/$conversationId/messages/$messageId/read',
        {},
      );
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all messages in conversation as read
  static Future<void> markConversationAsRead(String conversationId) async {
    try {
      await ApiService.post(
        '/conversations/$conversationId/read',
        {},
      );

      // Refresh conversations
      await getConversations();
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  /// Delete message
  static Future<void> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    try {
      await ApiService.delete(
        '/conversations/$conversationId/messages/$messageId',
      );

      // Refresh messages
      await getMessages(conversationId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  /// Edit message
  static Future<MessageModel?> editMessage(
    String conversationId,
    String messageId,
    String newContent, {
    String? encryptedContent,
    String? encryptionIv,
  }) async {
    try {
      final payload = {
        'content': newContent,
        if (encryptedContent != null) 'encryptedContent': encryptedContent,
        if (encryptionIv != null) 'encryptionIv': encryptionIv,
      };

      final response = await ApiService.put(
        '/conversations/$conversationId/messages/$messageId',
        payload,
      );

      return MessageModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error editing message: $e');
      return null;
    }
  }

  /// Search messages in conversation
  static Future<List<MessageModel>> searchMessages(
    String conversationId,
    String query,
  ) async {
    try {
      final response = await ApiService.get(
        '/conversations/$conversationId/messages/search?q=${Uri.encodeComponent(query)}',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Get conversation by ID
  static Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final response = await ApiService.get('/conversations/$conversationId');
      return ConversationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      return null;
    }
  }

  /// Add participant to conversation
  static Future<void> addParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      await ApiService.post(
        '/conversations/$conversationId/participants',
        {'userId': userId},
      );

      // Refresh conversation
      await getConversationById(conversationId);
    } catch (e) {
      debugPrint('Error adding participant: $e');
    }
  }

  /// Remove participant from conversation
  static Future<void> removeParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      await ApiService.delete(
        '/conversations/$conversationId/participants/$userId',
      );

      // Refresh conversation
      await getConversationById(conversationId);
    } catch (e) {
      debugPrint('Error removing participant: $e');
    }
  }

  /// Leave conversation
  static Future<void> leaveConversation(String conversationId) async {
    try {
      await ApiService.delete('/conversations/$conversationId/leave');

      // Refresh conversations
      await getConversations();
    } catch (e) {
      debugPrint('Error leaving conversation: $e');
    }
  }

  /// Delete conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      await ApiService.delete('/conversations/$conversationId');

      // Refresh conversations
      await getConversations();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }

  /// Setup real-time message listener (for WebSocket)
  static void listenForMessages(String conversationId) {
    // This can be enhanced with WebSocket in future
    // For now, periodic polling
    Timer.periodic(const Duration(seconds: 5), (_) async {
      await getMessages(conversationId);
    });
  }

  /// Cache conversations locally
  static Future<void> _cacheConversations(List<ConversationModel> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(
        _conversationCacheKey,
        jsonList.toString(),
      );
    } catch (e) {
      debugPrint('Error caching conversations: $e');
    }
  }

  /// Get cached conversations
  static Future<List<ConversationModel>> _getCachedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_conversationCacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Note: In production, use proper JSON parsing
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error retrieving cached conversations: $e');
      return [];
    }
  }

  /// Clear message cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messageCacheKey);
      await prefs.remove(_conversationCacheKey);
    } catch (e) {
      debugPrint('Error clearing message cache: $e');
    }
  }
}

/// Message type enum
enum MessageType {
  text,
  image,
  video,
  file,
  audio,
  location,
  system,
}
