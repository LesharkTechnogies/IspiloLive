import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UserService {
  /// GET /users/me
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/users/me');
    return response ?? {};
  }

  /// PUT /users/me
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('/users/me', data);
    return response ?? {};
  }

  /// GET /users/me/stats
  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await ApiService.get('/users/me/stats');
    return response ?? {};
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

    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

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
