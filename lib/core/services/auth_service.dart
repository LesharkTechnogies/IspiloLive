import 'dart:convert';
import 'package:flutter/foundation.dart'; // added kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'app_security_service.dart';
import 'push_notification_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await ApiService.post('/auth/login', {
      'phone': phone,
      'password': password,
    });

    // ApiService unwraps the `data` envelope and returns the inner payload.
    // The payload is expected to contain `accessToken` and `refreshToken`.
    if (response != null) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = response['accessToken'] ?? response['token'];
      final refreshToken = response['refreshToken'] ?? response['refresh_token'];
      if (accessToken != null) await prefs.setString('auth_token', accessToken);
      if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);

      // Persist login phone for linking later
      await prefs.setString('login_phone', phone);

      // Persist user payload if returned
      final user = response['user'];
      if (user is Map<String, dynamic>) {
        await prefs.setString('user_profile', jsonEncode(user));
        
        // Cache detailed profile string for EditProfile page fast-load
        await prefs.setString('profile_email', user['email']?.toString() ?? '');
        await prefs.setString('profile_phone', user['phone']?.toString() ?? '');
        await prefs.setString('profile_name', user['name']?.toString() ?? user['firstName']?.toString() ?? '');
        await prefs.setString('profile_username', user['username']?.toString() ?? '');
        
        if (user['phone'] is String) {
          await prefs.setString('login_phone', user['phone']);
        }
      }

      // Trigger app registration now that we have phone
      try {
        await AppSecurityService().registerAppAfterLogin(phone);
        if (!kIsWeb) {
          await PushNotificationService.initialize();
        }
      } catch (e) {
        // Non-fatal
      }
    }

    return response;
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String countryCode,
    required String county,
    required String town,
  }) async {
    return await ApiService.post('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'countryCode': countryCode,
      'county': county,
      'town': town,
    });
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  static Future<void> requestResetCode(String email) async {
    await ApiService.post('/auth/forgot-password/request-code', {
      'email': email,
    });
  }

  static Future<void> resendResetCode(String email) async {
    await ApiService.post('/auth/forgot-password/resend-code', {
      'email': email,
    });
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await ApiService.post('/auth/forgot-password/reset', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
