import 'package:ispilo/core/services/api_service.dart';
import 'package:dio/dio.dart';

/// User Repository for fetching user data, profile, stats, and preferences from Java API
class UserRepository {
  static const String _baseEndpoint = '/users';

  /// Get current logged-in user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/me');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch current user: $e');
    }
  }

  /// Get user by ID
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$userId');
      return response as Map<String, dynamic>;
    } catch (e) {
      try {
        final fallback = await ApiService.get('$_baseEndpoint/$userId/profile');
        return fallback as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Failed to fetch user: $e');
      }
    }
  }

  /// Get current user statistics (posts, followers, following, connections)
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/me/stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// Get user statistics by ID
  static Future<Map<String, dynamic>> getUserStatsById(String userId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$userId/stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// Get user preferences/settings
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/me/preferences');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user preferences: $e');
    }
  }

  /// Update user preferences/settings
  static Future<Map<String, dynamic>> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await ApiService.put(
        '$_baseEndpoint/me/preferences',
        preferences,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await ApiService.put(
        '$_baseEndpoint/me',
        profileData,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update user avatar
  static Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    try {
      final response = await ApiService.put(
        '$_baseEndpoint/me',
        {'avatar': avatarUrl},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    }
  }

  /// Upload user avatar (multipart)
  static Future<Map<String, dynamic>> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final file = MultipartFile.fromBytes(bytes, filename: fileName);
      final response = await ApiService.postMultipart(
        '$_baseEndpoint/me/avatar',
        files: {'file': file},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Follow a user
  static Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final response = await ApiService.post('$_baseEndpoint/$userId/follow', {});
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  static Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final response = await ApiService.delete('$_baseEndpoint/$userId/follow');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true};
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Toggle follow status for a user
  static Future<Map<String, dynamic>> toggleFollow(String userId) async {
    try {
      final response = await ApiService.post('$_baseEndpoint/$userId/follow/toggle', {});
      return response as Map<String, dynamic>;
    } catch (_) {
      // Fallback for backends that only support POST/DELETE follow endpoint
      final response = await ApiService.post('$_baseEndpoint/$userId/follow', {});
      return response as Map<String, dynamic>;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      await ApiService.delete('$_baseEndpoint/me');
    } catch (e) {
      try {
        await ApiService.delete('$_baseEndpoint/me/account');
      } catch (inner) {
        throw Exception('Failed to delete account: $e / $inner');
      }
    }
  }

  /// Get complete user profile with stats
  static Future<Map<String, dynamic>> getCompleteUserProfile(String userId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$userId');
      return response as Map<String, dynamic>;
    } catch (e) {
      try {
        final fallback = await ApiService.get('$_baseEndpoint/$userId/profile');
        return fallback as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Failed to fetch complete user profile: $e');
      }
    }
  }
}
