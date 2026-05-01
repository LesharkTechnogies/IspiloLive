import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:ispilo/model/message_model.dart';
import 'package:ispilo/model/social_model.dart';

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

  static final RegExp _tokenRegex = RegExp(r'[a-z0-9]+');

  static String _normalizeSearchText(String value) {
    return value.trim().toLowerCase();
  }

  static List<String> _tokenize(String value) {
    final normalized = _normalizeSearchText(value);
    if (normalized.isEmpty) return const <String>[];
    return _tokenRegex
        .allMatches(normalized)
        .map((match) => match.group(0) ?? '')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  /// Reusable and safer user matcher used across chat/search/group-selection UIs.
  ///
  /// - Matches against user name, username/email and id.
  /// - Uses tokenized query matching so multi-word search remains reliable.
  static bool matchesUserSearch(UserModel user, String query) {
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return true;

    final candidateTokens = <String>{
      ..._tokenize(user.name),
      ..._tokenize(user.username),
      ..._tokenize(user.id),
    };

    final flatCandidate = _normalizeSearchText(
      '${user.name} ${user.username} ${user.id}',
    );

    for (final token in queryTokens) {
      final tokenMatched = candidateTokens.any((candidate) =>
              candidate.contains(token) ||
              candidate.startsWith(token)) ||
          flatCandidate.contains(token);
      if (!tokenMatched) {
        return false;
      }
    }

    return true;
  }

  static List<UserModel> filterUsersByQuery(
    List<UserModel> users,
    String query,
  ) {
    if (query.trim().isEmpty) return users;
    return users.where((user) => matchesUserSearch(user, query)).toList();
  }

  /// Shared helper used by forwarding/group-creation/add-members flows.
  ///
  /// Combines discover/user endpoints and known conversation participants,
  /// dedupes by id, and excludes the current user.
  static Future<List<UserModel>> loadSelectableUsers({
    int size = 100,
  }) async {
    final deduped = <String, UserModel>{};
    final currentUserId = (await _currentUserIdFromPrefs())?.trim();

    Future<void> addFromDynamicList(dynamic response) async {
      final list = _extractListPayload(response);
      for (final item in list) {
        if (item is! Map) continue;
        try {
          final user = UserModel.fromJson(item.cast<String, dynamic>());
          final id = user.id.trim();
          if (id.isEmpty) continue;
          if (currentUserId != null && id == currentUserId) continue;
          deduped[id] = user;
        } catch (_) {
          // Skip malformed item.
        }
      }
    }

    final endpoints = <String>[
      '/users/discover?page=0&size=$size',
      '/users?page=0&size=$size',
      '/users',
      '/users/search?keyword=&page=0&size=$size',
      '/users/search?query=&page=0&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        await addFromDynamicList(response);
        if (deduped.length >= size) {
          break;
        }
      } catch (_) {
        // Try next endpoint.
      }
    }

    try {
      final conversations = await getConversations(size: size);
      for (final conversation in conversations) {
        for (final participant in conversation.participants) {
          final id = participant.id.trim();
          if (id.isEmpty) continue;
          if (currentUserId != null && id == currentUserId) continue;
          if (deduped.containsKey(id)) continue;

          deduped[id] = UserModel(
            id: id,
            username: participant.name,
            name: participant.name.trim().isNotEmpty ? participant.name : 'User',
            avatar: participant.avatar ?? '',
            isVerified: false,
            isOnline: participant.isOnline,
            isPremium: false,
            avatarPublic: true,
            lastSeenAt: participant.lastSeenAt,
          );
        }
      }
    } catch (_) {
      // Best effort enrichment only.
    }

    return deduped.values.take(size).toList(growable: false);
  }

  static List<dynamic> _extractListPayload(dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      final direct = response['content'] ??
          response['data'] ??
          response['items'] ??
          response['conversations'] ??
          response['users'] ??
          response['results'];

      if (direct is List) return direct;
      if (direct is Map<String, dynamic>) {
        final nested = direct['content'] ?? direct['data'] ?? direct['items'];
        if (nested is List) return nested;
      }
    }

    return const <dynamic>[];
  }

  static Map<String, dynamic>? _extractMapPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      final direct = response['data'];
      if (direct is Map<String, dynamic>) return direct;
      return response;
    }
    return null;
  }

  static Future<String?> _currentUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfile = prefs.getString('user_profile');
      if (userProfile == null || userProfile.isEmpty) return null;

      final decoded = jsonDecode(userProfile);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id']?.toString();
        if (id != null && id.trim().isNotEmpty) return id.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static ConversationModel? _parseFirstConversationFromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      final direct = _extractMapPayload(response);
      if (direct != null &&
          direct['id'] != null &&
          (direct['participants'] != null || direct['sellerId'] != null)) {
        try {
          return ConversationModel.fromJson(direct);
        } catch (_) {
          // Ignore parse errors and keep trying alternatives.
        }
      }
    }

    final list = _extractListPayload(response);
    if (list.isEmpty) return null;

    final first = list.first;
    if (first is Map<String, dynamic>) {
      try {
        return ConversationModel.fromJson(first);
      } catch (_) {
        return null;
      }
    }

    if (first is Map) {
      try {
        return ConversationModel.fromJson(first.cast<String, dynamic>());
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static String _apiMessageType(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.file:
        return 'FILE';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.location:
        return 'LOCATION';
      case MessageType.system:
        return 'SYSTEM';
    }
  }

  static Map<String, dynamic> _normalizeMessageMap(
    Map<String, dynamic> raw, {
    required String conversationId,
    required String fallbackText,
    required String fallbackType,
  }) {
    String? resolvedContent = raw['content'] as String?;
    if (resolvedContent == null || resolvedContent.isEmpty) {
      resolvedContent = raw['text'] as String?;
    }
    if (resolvedContent == null || resolvedContent.isEmpty) {
      if (raw['payload'] is Map) {
        resolvedContent = raw['payload']['text'] as String?;
      }
    }

    return {
      ...raw,
      'conversationId':
          raw['conversationId']?.toString() ?? conversationId,
      'content': resolvedContent ?? fallbackText,
      'type': raw['type'] ?? raw['mediaType'] ?? fallbackType,
      'createdAt': raw['createdAt'] ?? raw['timestamp'],
      'replyToMessageId': raw['replyToMessageId'],
      'reactions': raw['reactions'] ?? const <String, String>{},
    };
  }

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
      final currentUserId = await _currentUserIdFromPrefs();
      final endpoints = <String>[
        '/conversations?page=$page&size=$size',
        if (currentUserId != null) '/conversations?userId=$currentUserId&page=$page&size=$size',
        if (currentUserId != null) '/conversations?userId=$currentUserId',
        '/conversations',
      ];

      dynamic response;
      Object? lastError;
      for (final endpoint in endpoints) {
        try {
          response = await ApiService.get(endpoint);
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
        }
      }

      if (response == null && lastError != null) {
        throw lastError;
      }

      final List<dynamic> content = _extractListPayload(response);
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
      dynamic response;
      try {
        response = await ApiService.get(
          '/conversations/$conversationId/messages?page=$page&size=$size',
        );
      } catch (_) {
        // Fallback for limit-style pagination contract.
        response = await ApiService.get(
          '/conversations/$conversationId/messages?limit=$size',
        );
      }

      final List<dynamic> contentPayload = _extractListPayload(response);
      final messages = contentPayload.map((json) {
        final raw = json as Map<String, dynamic>;
        return MessageModel.fromJson(_normalizeMessageMap(
          raw,
          conversationId: conversationId,
          fallbackText: '',
          fallbackType: 'TEXT',
        ));
      }).toList();

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
    String? senderId,
    String? encryptedContent,
    String? encryptionIv,
    MessageType messageType = MessageType.text,
    String? replyToMessageId,
  }) async {
    try {
      final typeValue = _apiMessageType(messageType);
      final primaryPayload = {
        'text': content,
        'type': typeValue,
        if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
          'replyToMessageId': replyToMessageId,
        if (encryptedContent != null) 'encryptedContent': encryptedContent,
        if (encryptionIv != null) 'encryptionIv': encryptionIv,
      };

      debugPrint('==== SEND MESSAGE API DEBUG ====');
      debugPrint('Endpoint: POST /conversations/$conversationId/messages');
      debugPrint('Primary Payload Structure: $primaryPayload');
      debugPrint('Message Type Computed: $typeValue');
      debugPrint('=================================');

      dynamic response;
      try {
        response = await ApiService.post(
          '/conversations/$conversationId/messages',
          primaryPayload,
        );
      } catch (e) {
        debugPrint('Primary payload failed: $e. Retrying standard POST with legacy keys...');
        // Retry same endpoint using legacy payload shape.
        final legacyPayload = {
          'content': content,
          'type': typeValue.toLowerCase(),
          if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
            'replyToMessageId': replyToMessageId,
          if (encryptedContent != null) 'encryptedContent': encryptedContent,
          if (encryptionIv != null) 'encryptionIv': encryptionIv,
        };
        debugPrint('Legacy Payload Structure: $legacyPayload');
        
        try {
          response = await ApiService.post(
            '/conversations/$conversationId/messages',
            legacyPayload,
          );
        } catch (e) {
          debugPrint('Legacy payload failed: $e. Retrying fallback endpoint /messages in new shape...');
          // Fallback for alternative message endpoint shape.
          final fallbackPayload = {
            'conversationId': conversationId,
            'type': typeValue,
            'payload': {'text': content},
            if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
              'replyToMessageId': replyToMessageId,
          };
          debugPrint('Fallback Payload Structure: $fallbackPayload');
          
          response = await ApiService.post('/messages', fallbackPayload);
        }
      }

      final responseMap = _extractMapPayload(response);
      if (responseMap == null) {
        throw Exception('Invalid send message response');
      }

      final message = MessageModel.fromJson(
        _normalizeMessageMap(
          responseMap,
          conversationId: conversationId,
          fallbackText: content,
          fallbackType: typeValue,
        ),
      );

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
      final requestedParticipants = participantIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final currentUserId = await _currentUserIdFromPrefs();

      final normalizedParticipants = requestedParticipants
          .where((id) => id != currentUserId)
          .toList(growable: false);
      final targetUserId = normalizedParticipants.isNotEmpty
          ? normalizedParticipants.first
          : (requestedParticipants.isNotEmpty ? requestedParticipants.first : '');
      if (targetUserId.isEmpty) {
        debugPrint('Error creating conversation: target user id is empty');
        return null;
      }

      final displayName = name.trim();
      final shouldCreateGroup = isGroup || normalizedParticipants.length > 1;

      List<List<String>> buildGroupMemberVariants() {
        final variants = <List<String>>[];
        final seen = <String>{};

        void addVariant(List<String> ids) {
          final compact = ids
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList(growable: false);
          if (compact.isEmpty) return;
          final signature = compact.join('|');
          if (seen.add(signature)) {
            variants.add(compact);
          }
        }

        addVariant(normalizedParticipants);
        addVariant(requestedParticipants);
        if (currentUserId != null && currentUserId.trim().isNotEmpty) {
          addVariant(<String>[...normalizedParticipants, currentUserId]);
        }

        return variants;
      }

      final groupName = displayName.isNotEmpty ? displayName : 'Group chat';

      final attempts = shouldCreateGroup
          ? () {
              final generated = <Map<String, dynamic>>[];
              final seenAttempts = <String>{};

              void addAttempt(String url, Map<String, dynamic> body) {
                final key = '$url|${jsonEncode(body)}';
                if (seenAttempts.add(key)) {
                  generated.add({'url': url, 'body': body});
                }
              }

              for (final members in buildGroupMemberVariants()) {
                addAttempt('/conversations/group', {
                  'participantIds': members,
                  'members': members,
                  'isGroup': true,
                  'group': true,
                  'name': groupName,
                });
                addAttempt('/conversations', {
                  'participantIds': members,
                  'members': members,
                  'participants': members,
                  'isGroup': true,
                  'group': true,
                  'name': groupName,
                });
                addAttempt('/groups', {
                  'userIds': members,
                  'participantIds': members,
                  'members': members,
                  'isGroup': true,
                  'group': true,
                  'name': groupName,
                  'title': groupName,
                });
              }

              return generated;
            }()
          : [
              {
                'url': '/conversations',
                'body': {
                  'sellerId': targetUserId,
                  if (currentUserId != null) 'buyerId': currentUserId,
                  if (displayName.isNotEmpty) 'sellerName': displayName,
                }
              },
              {
                'url': '/conversations/direct',
                'body': {
                  'participantId': targetUserId,
                  if (currentUserId != null) 'userId': currentUserId,
                  if (displayName.isNotEmpty) 'name': displayName,
                }
              },
              {
                'url': '/conversations',
                'body': {
                  'participantIds': [targetUserId],
                  'isGroup': false,
                  if (displayName.isNotEmpty) 'name': displayName,
                }
              }
            ];

      dynamic response;
      Object? lastError;
      for (final attempt in attempts) {
        debugPrint('==== CREATE CONVERSATION API DEBUG ====');
        debugPrint('Endpoint: POST ${attempt['url']}');
        debugPrint('Payload: ${attempt['body']}');
        
        try {
          response = await ApiService.post(attempt['url'] as String, attempt['body'] as Map<String, dynamic>);
          lastError = null;
          debugPrint('Success: Created conversation at ${attempt['url']}');
          debugPrint('======================================');
          break;
        } catch (e) {
          lastError = e;
          debugPrint('Failed: $e');
        }
        debugPrint('======================================');
      }

      if (response == null) {
        debugPrint('All create endpoints failed, attempting recovery lookup...');
        // Recovery path: some backend builds may create the conversation but
        // still return an error payload/status. Try to locate it once.
        final recovered = shouldCreateGroup
            ? null
            : await findDirectConversation(targetUserId: targetUserId);
        if (recovered != null) {
          debugPrint('Recovery successful!');
          return recovered;
        }

        if (shouldCreateGroup) {
          debugPrint('Attempting group recovery via base direct conversation...');
          final base = await createConversation(
            name: groupName,
            participantIds: [targetUserId],
            isGroup: false,
          );
          if (base != null) {
            final remainingMembers = normalizedParticipants
                .where((id) => id != targetUserId)
                .toList(growable: false);

            if (remainingMembers.isNotEmpty) {
              await addParticipantsDefensive(
                conversationId: base.id,
                userIds: remainingMembers,
              );
            }

            final refreshed = await getConversationById(base.id);
            return refreshed ?? base;
          }
        }

        if (lastError != null) throw lastError;
        throw Exception('Conversation creation failed');
      }

      final data = _extractMapPayload(response) ??
          (() {
            final listPayload = _extractListPayload(response);
            if (listPayload.isEmpty) return null;
            final first = listPayload.first;
            if (first is Map<String, dynamic>) return first;
            if (first is Map) return first.cast<String, dynamic>();
            return null;
          })();
      if (data == null) {
        throw Exception('Invalid create conversation response');
      }

      final conversation = ConversationModel.fromJson(data);

      // Refresh conversations
      await getConversations();

      return conversation;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Find an existing 1:1 conversation with a specific target user.
  static Future<ConversationModel?> findDirectConversation({
    required String targetUserId,
  }) async {
    if (targetUserId.trim().isEmpty) return null;

    final currentUserId = await _currentUserIdFromPrefs();
    final encodedTargetUserId = Uri.encodeQueryComponent(targetUserId.trim());
    final encodedUserId = currentUserId == null
        ? null
        : Uri.encodeQueryComponent(currentUserId);

    final endpoints = <String>[
      if (encodedUserId != null)
        '/conversations?userId=$encodedUserId&sellerId=$encodedTargetUserId',
      if (encodedUserId != null)
        '/conversations?buyerId=$encodedUserId&sellerId=$encodedTargetUserId',
      if (encodedUserId != null)
        '/conversations?userId=$encodedUserId&participantId=$encodedTargetUserId',
      if (encodedUserId != null)
        '/conversations?userId=$encodedUserId&userId2=$encodedTargetUserId',
      if (encodedUserId != null)
        '/conversations?userId=$encodedUserId&userId=$encodedTargetUserId',
      if (encodedUserId != null)
        '/conversations/direct?participantId=$encodedTargetUserId&userId=$encodedUserId',
      '/conversations?userId=$encodedTargetUserId',
      '/conversations?participantId=$encodedTargetUserId',
      '/conversations/direct?participantId=$encodedTargetUserId',
    ];

    for (final endpoint in endpoints) {
      debugPrint('==== FIND CONVERSATION API DEBUG ====');
      debugPrint('Endpoint: GET $endpoint');
      try {
        final response = await ApiService.get(endpoint);
        final parsed = _parseFirstConversationFromResponse(response);
        if (parsed != null) {
          debugPrint('Success: Found conversation at $endpoint');
          debugPrint('====================================');
          return parsed;
        } else {
          debugPrint('No conversation found in response, continuing...');
        }
      } catch (e) {
        debugPrint('Failed at $endpoint: $e');
      }
      debugPrint('====================================');
    }

    return null;
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
      try {
        await ApiService.post(
          '/conversations/$conversationId/read',
          {},
        );
      } catch (_) {
        await ApiService.post(
          '/conversations/$conversationId/messages/read',
          {},
        );
      }

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

  /// Search users by name for starting/locating chats.
  static Future<List<UserModel>> searchUsersByName(
    String query, {
    int size = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <UserModel>[];

    final encodedQuery = Uri.encodeQueryComponent(trimmed);
    final endpoints = <String>[
      '/users/search?keyword=$encodedQuery&page=0&size=$size',
      '/users/search?query=$encodedQuery&page=0&size=$size',
      '/users?search=$encodedQuery&page=0&size=$size',
      '/users?query=$encodedQuery&page=0&size=$size',
      '/users/discover?keyword=$encodedQuery&page=0&size=$size',
      '/users/discover?query=$encodedQuery&page=0&size=$size',
      '/users/discover?page=0&size=${size * 2}',
    ];

    dynamic response;
    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        response = await ApiService.get(endpoint);
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
      }
    }

    if (response == null && lastError != null) {
      debugPrint('Error searching users: $lastError');
      return const <UserModel>[];
    }

    final rawList = _extractListPayload(response);
    final deduped = <String, UserModel>{};

    for (final item in rawList) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final user = UserModel.fromJson(map);
      if (user.id.trim().isEmpty) continue;

      if (!matchesUserSearch(user, trimmed)) continue;

      deduped[user.id] = user;
    }

    if (deduped.length < size) {
      try {
        final supplemental = await loadSelectableUsers(size: size * 2);
        for (final user in supplemental) {
          if (!matchesUserSearch(user, trimmed)) continue;
          deduped[user.id] = user;
          if (deduped.length >= size) break;
        }
      } catch (_) {
        // Best effort only.
      }
    }

    return deduped.values.take(size).toList();
  }

  /// Add a single participant with defensive payload/endpoint fallbacks.
  static Future<void> addParticipant(
    String conversationId,
    String userId,
  ) async {
    await addParticipantsDefensive(
      conversationId: conversationId,
      userIds: [userId],
    );
  }

  /// Add participants with defensive dynamic payload and endpoint fallbacks.
  static Future<int> addParticipantsDefensive({
    required String conversationId,
    required List<String> userIds,
  }) async {
    final cleanConversationId = conversationId.trim();
    if (cleanConversationId.isEmpty) return 0;

    final ids = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return 0;

    var successCount = 0;

    for (final userId in ids) {
      final attempts = <Map<String, dynamic>>[
        {
          'url': '/conversations/$cleanConversationId/participants',
          'body': {'userId': userId},
        },
        {
          'url': '/conversations/$cleanConversationId/participants',
          'body': {'participantId': userId},
        },
        {
          'url': '/conversations/$cleanConversationId/members',
          'body': {'userId': userId},
        },
        {
          'url': '/groups/$cleanConversationId/members',
          'body': {'memberId': userId},
        },
      ];

      var added = false;
      for (final attempt in attempts) {
        try {
          await ApiService.post(
            attempt['url'] as String,
            attempt['body'] as Map<String, dynamic>,
          );
          added = true;
          break;
        } catch (_) {
          // Try next fallback.
        }
      }

      if (added) {
        successCount++;
      }
    }

    return successCount;
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
