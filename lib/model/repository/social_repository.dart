import 'package:ispilo/core/services/api_service.dart';
import 'package:ispilo/model/social_model.dart';

/// Repository for social feed API calls
class PostRepository {
  static const String _baseEndpoint = '/posts';

  static List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final direct = response['content'] ??
          response['data'] ??
          response['items'] ??
          response['results'];
      if (direct is List) return direct;
      if (direct is Map<String, dynamic>) {
        final nested = direct['content'] ?? direct['data'] ?? direct['items'];
        if (nested is List) return nested;
      }
    }
    return const <dynamic>[];
  }

  /// Get feed posts with pagination
  static Future<List<PostModel>> getFeed({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/feed?page=$page&size=$size');
      final content = _extractList(response);
      return content
          .whereType<Map>()
          .map((json) => PostModel.fromJson(json.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get group posts feed (mixed group posts)
  static Future<List<PostModel>> getGroupFeed({
    int page = 0,
    int size = 20,
  }) async {
    final endpoints = <String>[
      '$_baseEndpoint/groups/feed?page=$page&size=$size',
      '$_baseEndpoint/group/feed?page=$page&size=$size',
      '/groups/posts/feed?page=$page&size=$size',
      '$_baseEndpoint/feed?type=group&page=$page&size=$size',
      '$_baseEndpoint?group=true&page=$page&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        final content = _extractList(response);
        return content
            .whereType<Map>()
            .map((json) => PostModel.fromJson(json.cast<String, dynamic>()))
            .toList();
      } catch (_) {
        // Try next endpoint.
      }
    }

    return const <PostModel>[];
  }

  /// Get posts for a specific group
  static Future<List<PostModel>> getPostsByGroup({
    required String groupId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get('/groups/$groupId/posts?page=$page&size=$size');
      final List<dynamic> content = response['content'] as List? ?? response['data'] as List? ?? [];
      return content
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch group posts: $e');
    }
  }

  /// Create a new group post
  static Future<PostModel> createGroupPost({
    required String groupId,
    required String content,
    List<String>? mediaUrls,
    bool isAnonymous = false,
  }) async {
    try {
      final payload = {
        'actualContent': content,
        'mediaUrls': mediaUrls ?? [],
        'isAnonymous': isAnonymous,
      };

      final response = await ApiService.post('/groups/$groupId/posts', payload);
      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create group post: $e');
    }
  }

  /// Create a new group
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
    bool isPrivate = false,
  }) async {
    try {
      final payload = {
        'name': name,
        'description': description,
        'privateGroup': isPrivate,
      };
         final response = await ApiService.post('/groups', payload);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Get list of groups
  static Future<List<Map<String, dynamic>>> getGroups({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get('/groups?page=$page&size=$size');
      final List<dynamic> content = response['content'] as List? ?? response['data'] as List? ?? [];
      return content.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Join group
  static Future<void> joinGroup(String groupId) async {
    try {
      await ApiService.post('/groups/$groupId/join', {});
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  /// Get post by ID
  static Future<PostModel> getPostById(String postId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$postId');
      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Get posts by user
  static Future<List<PostModel>> getPostsByUser(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final endpoints = <String>[
      '/users/$userId/posts?page=$page&size=$size',
      '$_baseEndpoint/user/$userId?page=$page&size=$size',
      '/posts/user/$userId?page=$page&size=$size',
      '/users/$userId/posts?page=$page&size=$size',
      '$_baseEndpoint?userId=$userId&page=$page&size=$size',
      '$_baseEndpoint/users/$userId?page=$page&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.getWithFallback(endpoint);
        final content = _extractList(response);
        return content
            .whereType<Map>()
            .map((json) => PostModel.fromJson(json.cast<String, dynamic>()))
            .toList();
      } catch (_) {
        // Try next endpoint
      }
    }
    
    // If all fail, return an empty list rather than crashing the UI
    return [];
  }

  /// Get posts for the authenticated user
  static Future<List<PostModel>> getMyPosts({
    int page = 0,
    int size = 20,
  }) async {
    final endpoints = <String>[
      '/users/me/posts?page=$page&size=$size',
      '$_baseEndpoint/me?page=$page&size=$size',
      '/posts/me?page=$page&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.getWithFallback(endpoint);
        final content = _extractList(response);
        return content
            .whereType<Map>()
            .map((json) => PostModel.fromJson(json.cast<String, dynamic>()))
            .toList();
      } catch (_) {
        // Try next endpoint.
      }
    }

    return [];
  }

  /// Create a new post
  static Future<PostModel> createPost({
    required String description,
    List<String>? mediaUrls,
  }) async {
    try {
      final payload = {
        'description': description,
        'mediaUrls': mediaUrls ?? [],
      };

      final response = await ApiService.post(_baseEndpoint, payload);
      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Update post
  static Future<PostModel> updatePost({
    required String postId,
    required String content,
    List<String>? images,
  }) async {
    try {
      final payload = {
        'content': content,
        'mediaUrls': images,
      };

      final response = await ApiService.put('$_baseEndpoint/$postId', payload);
      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Delete post
  static Future<void> deletePost(String postId) async {
    try {
      await ApiService.delete('$_baseEndpoint/$postId');
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Toggle Like post
  static Future<PostModel> toggleLikePost(String postId) async {
    try {
      final response = await ApiService.post('$_baseEndpoint/$postId/like', {});
      return PostModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to toggle like post: $e');
    }
  }

  /// Save post
  static Future<void> savePost(String postId) async {
    try {
      await ApiService.post('$_baseEndpoint/$postId/save', {});
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  /// Unsave post
  static Future<void> unsavePost(String postId) async {
    try {
      await ApiService.delete('$_baseEndpoint/$postId/save');
    } catch (e) {
      throw Exception('Failed to unsave post: $e');
    }
  }

  /// Get post comments
  static Future<List<CommentModel>> getComments({
    required String postId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/$postId/comments?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Add comment to post
  static Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await ApiService.post(
        '$_baseEndpoint/$postId/comments',
        {
          'text': content,
          'content': content,
          if (parentCommentId != null && parentCommentId.isNotEmpty)
            'parentCommentId': parentCommentId,
        },
      );

      if (response is Map<String, dynamic>) {
        final dynamic commentPayload = response['comment'] ?? response['data'] ?? response;
        if (commentPayload is Map<String, dynamic>) {
          return CommentModel.fromJson(commentPayload);
        }
      }

      throw Exception('Unexpected add comment response format');
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Add a reply to an existing comment
  static Future<CommentModel> addReply({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    // Uses the updated backend tree logic:
    return addComment(
      postId: postId,
      content: content,
      parentCommentId: commentId,
    );
  }

  /// Toggle like on a comment/reply
  static Future<Map<String, dynamic>> toggleLikeComment(String commentId) async {
    try {
      final response = await ApiService.post('/comments/$commentId/like', {});

      if (response is Map<String, dynamic>) {
        final dynamic payload = response['data'] ?? response;
        if (payload is Map<String, dynamic>) {
          final isLiked = payload['isLiked'] as bool? ?? false;
          final likes = payload['likes'] ?? payload['likesCount'];

          return {
            'isLiked': isLiked,
            'likesCount': likes is int ? likes : int.tryParse(likes?.toString() ?? '0') ?? 0,
          };
        }
      }

      throw Exception('Unexpected comment like response format');
    } catch (e) {
      throw Exception('Failed to like/unlike comment: $e');
    }
  }

  /// Delete comment
  static Future<void> deleteComment(String commentId) async {
    try {
      await ApiService.delete('/comments/$commentId');
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}

/// Repository for user API calls
class UserRepository {
  static const String _baseEndpoint = '/users';

  static List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final direct = response['content'] ??
          response['data'] ??
          response['items'] ??
          response['users'] ??
          response['results'];
      if (direct is List) return direct;
      if (direct is Map<String, dynamic>) {
        final nested = direct['content'] ?? direct['items'] ?? direct['users'];
        if (nested is List) return nested;
      }
    }
    return const <dynamic>[];
  }

  /// Get current user profile
  static Future<UserModel> getCurrentUser() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/me');
      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch current user: $e');
    }
  }

  /// Get user by ID
  static Future<UserModel> getUserById(String userId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$userId');
      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Get users to follow (suggestions)
  static Future<List<UserModel>> getUserSuggestions({
    int page = 0,
    int size = 10,
  }) async {
    final endpoints = <String>[
      '$_baseEndpoint/discover?page=$page&size=$size',
      '$_baseEndpoint/suggestions?page=$page&size=$size',
      '$_baseEndpoint?discover=true&page=$page&size=$size',
      '$_baseEndpoint?page=$page&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        final rawUsers = _extractList(response);
        final users = <UserModel>[];
        for (final raw in rawUsers) {
          if (raw is Map<String, dynamic>) {
            users.add(UserModel.fromJson(raw));
          } else if (raw is Map) {
            users.add(UserModel.fromJson(raw.cast<String, dynamic>()));
          }
        }

        final filtered = users
            .where((user) => user.id.trim().isNotEmpty)
            .toList(growable: false);
        if (filtered.isNotEmpty) {
          return filtered;
        }
      } catch (_) {
        // Try next endpoint.
      }
    }

    return []; // Return empty list on error
  }

  /// Get followers list for a user
  static Future<List<UserModel>> getFollowers({
    required String userId,
    int size = 50,
  }) async {
    final endpoints = <String>[
      '$_baseEndpoint/$userId/followers',
      '$_baseEndpoint/$userId/followers?page=0&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        final rawUsers = _extractList(response);
        return rawUsers
            .whereType<Map>()
            .map((raw) => UserModel.fromJson(raw.cast<String, dynamic>()))
            .where((user) => user.id.trim().isNotEmpty)
            .toList(growable: false);
      } catch (_) {
        // Try next endpoint.
      }
    }

    return [];
  }

  /// Get following list for a user
  static Future<List<UserModel>> getFollowing({
    required String userId,
    int size = 50,
  }) async {
    final endpoints = <String>[
      '$_baseEndpoint/$userId/following',
      '$_baseEndpoint/$userId/following?page=0&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        final rawUsers = _extractList(response);
        return rawUsers
            .whereType<Map>()
            .map((raw) => UserModel.fromJson(raw.cast<String, dynamic>()))
            .where((user) => user.id.trim().isNotEmpty)
            .toList(growable: false);
      } catch (_) {
        // Try next endpoint.
      }
    }

    return [];
  }

  /// Get mutual connections list for a user
  static Future<List<UserModel>> getConnections({
    required String userId,
    int size = 50,
  }) async {
    final endpoints = <String>[
      '$_baseEndpoint/$userId/connections',
      '$_baseEndpoint/$userId/connections?page=0&size=$size',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await ApiService.get(endpoint);
        final rawUsers = _extractList(response);
        return rawUsers
            .whereType<Map>()
            .map((raw) => UserModel.fromJson(raw.cast<String, dynamic>()))
            .where((user) => user.id.trim().isNotEmpty)
            .toList(growable: false);
      } catch (_) {
        // Try next endpoint.
      }
    }

    return [];
  }

  /// Follow user
  static Future<void> followUser(String userId) async {
    try {
      await ApiService.post('$_baseEndpoint/$userId/follow', {});
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow user
  static Future<void> unfollowUser(String userId) async {
    try {
      await ApiService.delete('$_baseEndpoint/$userId/follow');
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Update user profile with selective fields (only non-null fields are sent)
  static Future<UserModel> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    String? location,
    String? company,
    String? quote,
    bool? avatarPublic,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) {
        payload['name'] = name;
        final parts = name.trim().split(' ');
        payload['firstName'] = parts.first;
        payload['lastName'] = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;
      }
      if (bio != null) payload['bio'] = bio;
      if (avatar != null) {
        payload['avatar'] = avatar;
        payload['avatarUrl'] = avatar;
        payload['profileImage'] = avatar;
        payload['profilePicture'] = avatar;
      }
      if (location != null) payload['location'] = location;
      if (company != null) payload['company'] = company;
      if (quote != null) payload['quote'] = quote;
      if (avatarPublic != null) payload['avatarPublic'] = avatarPublic;

      final response = await ApiService.put('$_baseEndpoint/me', payload);
      
      if (avatar != null) {
        try {
          await ApiService.put('$_baseEndpoint/me/avatar', {'avatar': avatar, 'url': avatar, 'avatarUrl': avatar});
        } catch (_) {}
      }

      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
