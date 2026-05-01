import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UserService {
  static Map<String, dynamic> _unwrapMap(dynamic response) {
    if (response is! Map<String, dynamic>) return <String, dynamic>{};

    final data = response['data'];
    if (data is Map<String, dynamic>) return data;

    final user = response['user'];
    if (user is Map<String, dynamic>) return user;

    final profile = response['profile'];
    if (profile is Map<String, dynamic>) return profile;

    return response;
  }

  /// GET /users/me
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/users/me');
    return _unwrapMap(response);
  }

  /// PUT /users/me
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/me', data);
    return _unwrapMap(response);
  }

  /// GET /users/me/stats
  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await ApiService.get('/users/me/stats');
    return response ?? {};
  }

  /// GET /users/{userId}/stats
  static Future<Map<String, dynamic>> getUserStatsById(String userId) async {
    if (userId.trim().isEmpty) return {};
    final response = await ApiService.get('/users/$userId/stats');
    return response ?? {};
  }

  /// GET /users/{userId}
  /// Returns public/non-sensitive profile details for another user.
  static Future<Map<String, dynamic>> getUserProfileById(String userId) async {
    if (userId.trim().isEmpty) return {};

    Map<String, dynamic> profile;
    try {
      final response = await ApiService.getWithFallback('/users/$userId');
      profile = _unwrapMap(response);
    } catch (_) {
      // Backward-compatible fallback for older backend contracts.
      final fallback = await ApiService.getWithFallback('/users/$userId/profile');
      profile = _unwrapMap(fallback);
    }

    try {
      final stats = await getUserStatsById(userId);
      if (stats.isNotEmpty) {
        profile = {
          ...profile,
          'followers': profile['followers'] ?? stats['followers'],
          'followersCount': profile['followersCount'] ?? stats['followersCount'] ?? stats['followers'],
          'following': profile['following'] ?? stats['following'],
          'followingCount': profile['followingCount'] ?? stats['followingCount'] ?? stats['following'],
          'connections': profile['connections'] ?? stats['connections'],
          'connectionsCount': profile['connectionsCount'] ?? stats['connectionsCount'] ?? stats['connections'],
          'posts': profile['posts'] ?? stats['posts'] ?? stats['postCount'],
          'postCount': profile['postCount'] ?? stats['postCount'] ?? stats['posts'],
        };
      }
    } catch (_) {
      // Best effort only.
    }

    return profile;
  }

  /// GET /users/me/preferences
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final response = await ApiService.get('/users/me/preferences');
    return response ?? {};
  }

  /// PUT /users/me/preferences
  static Future<Map<String, dynamic>> updateUserPreferences(Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/me/preferences', data);
    return response ?? {};
  }

  /// DELETE /users/me/account
  static Future<void> deleteAccount() async {
    await ApiService.delete('/users/me/account');
  }

  /// POST /users/me/avatar (Multipart)
  static Future<Map<String, dynamic>> updateAvatar(String filePath) async {
    final headers = await ApiService.getHeaders();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/users/me/avatar'),
    );
    
    // Add headers to multipart request
    headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-type') {
         request.headers[key] = value;
      }
    });

    if (kIsWeb && filePath.startsWith('blob:')) {
      final fileResponse = await http.get(Uri.parse(filePath));
      final ext = filePath.split('.').last.split('?').first;
      final filename = 'avatar.${ext.isEmpty ? 'jpg' : ext}';
      request.files.add(http.MultipartFile.fromBytes('avatar', fileResponse.bodyBytes, filename: filename));
      request.files.add(http.MultipartFile.fromBytes('file', fileResponse.bodyBytes, filename: filename));
    } else {
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception('Failed to upload avatar: ${response.statusCode} - ${response.body}');
    }
  }

  /// POST /users/me/password
  static Future<void> updatePassword(String currentPassword, String newPassword) async {
    await ApiService.post('/users/me/password', {
      'oldPassword': currentPassword,
      'newPassword': newPassword,
      'password': newPassword, // Provided depending on backend DTO naming convention
    });
  }
}
