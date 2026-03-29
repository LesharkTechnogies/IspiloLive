import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';

class AppSecurityService {
  static final AppSecurityService _instance = AppSecurityService._internal();
  factory AppSecurityService() => _instance;
  AppSecurityService._internal();

  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  // Storage keys
  static const String _kAppId = 'app_id';
  static const String _kAppPrivateKey = 'app_private_key';
  static const String _kDeviceId = 'device_id';
  static const String _kServerPublicKey = 'server_public_key';
  static const String _kPendingAppRegistration = 'pending_app_registration';

  String? _cachedAppId;
  String? _cachedDeviceId;
  String? _cachedPrivateKey;
  String? _cachedServerPublicKey;

  /// Initialize security service: load creds, prep pending registration if needed
  Future<void> initialize() async {
    try {
      await _loadCredentials();
      if (_cachedAppId == null || _cachedPrivateKey == null) {
        await _prepareRegistrationPayload();
      }
    } catch (e) {
      debugPrint('AppSecurityService.initialize error (app will continue): $e');
    }
  }

  /// Load credentials from storage
  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      _cachedAppId = prefs.getString(_kAppId);
      _cachedPrivateKey = prefs.getString(_kAppPrivateKey);
      _cachedServerPublicKey = prefs.getString(_kServerPublicKey);
    } else {
      _cachedAppId = await _storage.read(key: _kAppId);
      _cachedPrivateKey = await _storage.read(key: _kAppPrivateKey);
      _cachedServerPublicKey = await _storage.read(key: _kServerPublicKey);
    }

    _cachedDeviceId = prefs.getString(_kDeviceId);
    if (_cachedDeviceId == null) {
      _cachedDeviceId = _uuid.v4();
      await prefs.setString(_kDeviceId, _cachedDeviceId!);
    }
  }

  /// Build and store pending registration payload (no phone yet)
  Future<void> _prepareRegistrationPayload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kPendingAppRegistration)) return;

      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceName = 'Unknown';
      String osVersion = 'Unknown';
      String platform = 'WEB';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceName = webInfo.browserName.name;
        osVersion = webInfo.platform ?? 'Unknown';
        platform = 'WEB';
      } else {
        try {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
          osVersion = androidInfo.version.release;
          platform = 'ANDROID';
        } catch (_) {
          try {
            final iosInfo = await deviceInfo.iosInfo;
            deviceName = iosInfo.name;
            osVersion = iosInfo.systemVersion;
            platform = 'IOS';
          } catch (_) {}
        }
      }

      final pending = {
        'deviceId': _cachedDeviceId,
        'deviceName': deviceName,
        'osVersion': osVersion,
        'appVersion': packageInfo.version,
        'platform': platform,
        'phone': null,
      };

      await prefs.setString(_kPendingAppRegistration, jsonEncode(pending));
      debugPrint('Prepared pending app registration payload');
    } catch (e) {
      debugPrint('Failed to prepare pending registration: $e');
    }
  }

  /// Register the app with the backend after login (requires phone)
  Future<void> registerAppAfterLogin(String phone) async {
    if (_cachedAppId != null && _cachedPrivateKey != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? payloadString = prefs.getString(_kPendingAppRegistration);
      if (payloadString == null) {
        await _prepareRegistrationPayload();
        payloadString = prefs.getString(_kPendingAppRegistration);
      }

      if (payloadString == null) {
        debugPrint('No pending registration payload found');
        return;
      }

      final payload = jsonDecode(payloadString);
      if (payload is! Map) {
        debugPrint('Invalid pending registration payload');
        return;
      }

      payload['phone'] = phone;

      final response = await ApiService.post('/registerApp', payload);

      if (response != null && response['success'] == true) {
        final appId = response['appId'] as String?;
        final appPrivateKey = response['appPrivateKey'] as String?;
        final serverPublicKey = response['serverPublicKey'] as String?;

        if (kIsWeb) {
          await prefs.setString(_kAppId, appId ?? '');
          await prefs.setString(_kAppPrivateKey, appPrivateKey ?? '');
          await prefs.setString(_kServerPublicKey, serverPublicKey ?? '');
        } else {
          await _storage.write(key: _kAppId, value: appId);
          await _storage.write(key: _kAppPrivateKey, value: appPrivateKey);
          await _storage.write(key: _kServerPublicKey, value: serverPublicKey);
        }

        _cachedAppId = appId;
        _cachedPrivateKey = appPrivateKey;
        _cachedServerPublicKey = serverPublicKey;
        await prefs.remove(_kPendingAppRegistration);
        debugPrint('App registered successfully after login: $appId');
      }
    } catch (e) {
      debugPrint('Failed to register app after login: $e');
    }
  }

  /// Get security headers for API requests
  Future<Map<String, String>> getSecurityHeaders() async {
    if (_cachedAppId == null || _cachedPrivateKey == null) {
      await initialize();
    }

    if (_cachedAppId == null || _cachedPrivateKey == null || _cachedDeviceId == null) {
      return {};
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _uuid.v4();
    final signatureBase = '$_cachedAppId$_cachedDeviceId$timestamp$nonce$_cachedPrivateKey';
    final signature = sha256.convert(utf8.encode(signatureBase)).toString();

    return {
      'X-App-ID': _cachedAppId!,
      'X-Device-ID': _cachedDeviceId!,
      'X-App-Signature': signature,
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
    };
  }

  String? get serverPublicKey => _cachedServerPublicKey;
}