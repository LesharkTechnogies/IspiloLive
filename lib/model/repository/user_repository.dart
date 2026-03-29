import 'package:ispilo/core/services/api_service.dart';

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
      final response = await ApiService.get('$_baseEndpoint/$userId/profile');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
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

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      await ApiService.delete('$_baseEndpoint/me/account');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Get complete user profile with stats
  static Future<Map<String, dynamic>> getCompleteUserProfile(String userId) async {
    try {
      final response = await ApiService.get('$_baseEndpoint/$userId/profile');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch complete user profile: $e');
    }
  }
}
