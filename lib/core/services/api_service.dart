import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_security_service.dart';
import 'api_version_notifier.dart';

class ApiService {
  // Use the Heroku URL for production (API prefix v1 per API contract)
  static const String baseUrl = 'https://ispilo-backend-32613e7af752.herokuapp.com/api/v1';
  // Legacy/alias base (non-versioned) for endpoints not yet versioned, e.g., auth
  static const String aliasBaseUrl = 'https://ispilo-backend-32613e7af752.herokuapp.com/api';

  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = includeAuth ? prefs.getString('auth_token') : null;

    // Get security headers
    final appSecurity = AppSecurityService();
    final securityHeaders = await appSecurity.getSecurityHeaders();

    final pkg = await PackageInfo.fromPlatform();
    final appVersion = pkg.version; // e.g. 1.0.0
    final buildNumber = pkg.buildNumber; // e.g. 42
    final platformHeader = _platformLabel();
    final clientIp = await _getClientIp();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'IspiloApp/$appVersion',
      if (token != null) 'Authorization': 'Bearer $token',
      // Device/app info for analytics and debugging
      'X-App-Version': appVersion,
      'X-Build-Number': buildNumber,
      'X-Platform': platformHeader,
      if (clientIp != null) 'X-IP': clientIp,
      // Add security headers
      ...securityHeaders,
    };
  }

  /// Simple remote version check (dev: backend-driven, not Play Store)
  /// Expects response with keys like { min_build, latest_build, force_update, update_url }
  static Future<Map<String, dynamic>?> fetchRemoteVersion() async {
    final resp = await get('/app/version');
    return resp is Map<String, dynamic> ? resp : null;
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
    if (defaultTargetPlatform == TargetPlatform.fuchsia) return 'fuchsia';
    return 'unknown';
  }

  static String? _cachedIp;

  static Future<String?> _getClientIp() async {
    if (_cachedIp != null) return _cachedIp;
    try {
      final resp = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['ip'] is String) {
          _cachedIp = data['ip'] as String;
          return _cachedIp;
        }
      }
    } catch (e) {
      debugPrint('IP fetch failed: $e');
    }
    return _cachedIp;
  }

  static void _logRequest(String method, String url, Map<String, String> headers, dynamic body) {
    debugPrint('[API] $method $url');
    debugPrint('[API] Headers: ${headers.map((k, v) => MapEntry(k, v))}');
    if (body != null) {
      debugPrint('[API] Body: $body');
    }
  }

  /// GET request with error handling
  static Future<dynamic> get(String endpoint) async {
    try {
      final headers = endpoint == '/app/version'
          ? await getHeaders(includeAuth: false)
          : await getHeaders();

      final url = '$baseUrl$endpoint';
      _logRequest('GET', url, headers, null);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException('Request timeout'),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// POST request with error handling
  static Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      // Allow auth endpoints to hit the non-versioned alias until backend is versioned
      final base = endpoint.startsWith('/auth/') ? aliasBaseUrl : baseUrl;

      // For public auth endpoints (register/login), avoid sending app security headers
      final isPublicAuth = endpoint == '/auth/register' || endpoint == '/auth/login';

      // Special handling for app registration to avoid circular dependency loop
      if (endpoint == '/registerApp') {
        // Build minimal headers plus fingerprint (platform/version/build/IP)
        final pkg = await PackageInfo.fromPlatform();
        final appVersion = pkg.version;
        final buildNumber = pkg.buildNumber;
        final platformHeader = _platformLabel();
        final ip = await _getClientIp();

        final registerHeaders = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'IspiloApp/$appVersion',
          'X-App-Version': appVersion,
          'X-Build-Number': buildNumber,
          'X-Platform': platformHeader,
          if (ip != null) 'X-IP': ip,
        };

  final registerUrl = '$base$endpoint';
        _logRequest('POST', registerUrl, registerHeaders, data);
        try {
          final response = await http.post(
            Uri.parse(registerUrl),
            headers: registerHeaders,
            body: jsonEncode(data),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw ApiException('Request timeout'),
          );
          try {
            return _handleResponse(response);
          } on ApiException catch (apiError) {
            debugPrint('Register response error (non-fatal): $apiError');
            return {
              'error': apiError.toString(),
              'status': response.statusCode,
              'body': response.body,
            };
          }
        } catch (e) {
          debugPrint('Register request failed (non-fatal): $e');
          return {'error': e.toString()};
        }
      }

      // Build headers
      final headers = isPublicAuth
          ? {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            }
          : await getHeaders();

      final url = '$base$endpoint';
      _logRequest('POST', url, headers, data);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException('Request timeout'),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// PUT request with error handling
  static Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException('Request timeout'),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// DELETE request with error handling
  static Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException('Request timeout'),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Handle HTTP response and error codes
  static dynamic _handleResponse(http.Response response) {
    try {
      final statusCode = response.statusCode;

      // Update API version/deprecation signals for UI
      ApiVersionNotifier.instance.updateFromHeaders(response.headers);

      if (statusCode >= 200 && statusCode < 300) {
        if (response.body.isEmpty) return null;
        final body = jsonDecode(response.body);
        // Support several common envelope shapes so callers don't need to
        // repeatedly check for `data` / `content` fields.
        if (body is Map) {
          // If backend returns `{ data: { ... } }` at top-level
          // We will only strip `data` if it doesn't conflict. 
          // Usually, pagination uses 'content', which we will NOT strip here
          // because it causes TypeError inside repositories expecting the Map.
          if (body.containsKey('data') && body.keys.length == 1) {
            return body['data'];
          }
        }
        return body;
      }

      // Handle specific error codes
      switch (statusCode) {
        case 400:
          throw ApiException('Bad request: ${_getErrorMessage(response)}');
        case 401:
          // Token expired or invalid - clear local storage
          _handleUnauthorized();
          throw ApiException('Unauthorized - Please login again');
        case 403:
          throw ApiException('Forbidden: You do not have permission');
        case 404:
          throw ApiException('Resource not found');
        case 409:
          throw ApiException('Conflict: ${_getErrorMessage(response)}');
        case 429:
          throw ApiException('Too many requests - Please try again later');
        case 500:
          throw ApiException('Server error - Please try again later');
        case 503:
          throw ApiException('Service unavailable - Please try again later');
        default:
          throw ApiException('Error $statusCode: ${_getErrorMessage(response)}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e');
    }
  }

  /// Extract error message from response
  static String _getErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'] ?? 'Unknown error';
      }
      if (data is Map && data.containsKey('error')) {
        return data['error'] ?? 'Unknown error';
      }
      return response.body;
    } catch (_) {
      return response.body;
    }
  }

  /// Handle unauthorized access - clear token and redirect to login
  static Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    // TODO: Trigger navigation to login screen using your routing mechanism
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
