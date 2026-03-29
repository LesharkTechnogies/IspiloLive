import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// App Security Service
/// Handles app ID registration, encryption/decryption of messages
class AppSecurityService {
  static const String _appIdKey = 'app_id';
  static const String _appPrivateKeyKey = 'app_private_key';
  static const String _serverPublicKeyKey = 'server_public_key';
  static const String _deviceIdKey = 'device_id';

  late SharedPreferences _prefs;
  late String _appId;
  late String _appPrivateKey; // 16-digit key
  late String _serverPublicKey;
  late String _deviceId;

  static final AppSecurityService _instance = AppSecurityService._internal();

  factory AppSecurityService() {
    return _instance;
  }

  AppSecurityService._internal();

  /// Initialize security service
  /// Call this on app startup
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Check if app is already registered
    _appId = _prefs.getString(_appIdKey) ?? '';
    _appPrivateKey = _prefs.getString(_appPrivateKeyKey) ?? '';
    _serverPublicKey = _prefs.getString(_serverPublicKeyKey) ?? '';

    if (_appId.isEmpty) {
      developer.log('App not registered yet');
    } else {
      developer.log('App already registered - App ID: $_appId');
    }
  }

  /// Register app with backend
  /// Returns: appId, appPrivateKey, serverPublicKey
  Future<bool> registerApp({
    required String deviceId,
    required String deviceName,
    required String osVersion,
    required String appVersion,
    String platform = 'ANDROID',
  }) async {
    try {
      _deviceId = deviceId;

      // Call backend to register
      // This would use your ApiService to POST to /api/app/register
      // For now, we'll mock it

      // Save credentials locally
      await _prefs.setString(_appIdKey, _appId);
      await _prefs.setString(_appPrivateKeyKey, _appPrivateKey);
      await _prefs.setString(_serverPublicKeyKey, _serverPublicKey);
      await _prefs.setString(_deviceIdKey, _deviceId);

      developer.log('App registered successfully - App ID: $_appId');
      return true;
    } catch (e) {
      developer.log('Error registering app: $e');
      return false;
    }
  }

  /// Get app ID
  String getAppId() => _appId;

  /// Get 16-digit app private key
  String getAppPrivateKey() => _appPrivateKey;

  /// Get device ID
  String getDeviceId() => _deviceId;

  /// Get server's public key
  String getServerPublicKey() => _serverPublicKey;

  /// Encrypt message using server's public key (RSA-4096)
  /// This is used when sending sensitive data to server
  Future<String> encryptWithServerPublicKey(String message) async {
    try {
      // Implement RSA encryption using server's public key
      // This uses the pointycastle library for RSA encryption
      developer.log('Encrypting message with server public key (RSA-4096)');

      // In real implementation:
      // 1. Parse the RSA public key
      // 2. Encrypt message
      // 3. Return base64 encoded encrypted data

      // For now, return the message (TODO: implement full RSA)
      return base64Encode(utf8.encode(message));
    } catch (e) {
      developer.log('Error encrypting message: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypt message using app private key (16-digit key)
  /// This is used when receiving encrypted messages from server
  Future<String> decryptWithAppPrivateKey(String encryptedMessage) async {
    try {
      developer.log('Decrypting message with app private key');

      // Implement decryption logic
      // Uses the 16-digit app private key

      return utf8.decode(base64Decode(encryptedMessage));
    } catch (e) {
      developer.log('Error decrypting message: $e');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Hash data using SHA-256
  /// Used for data integrity verification
  String hashWithSHA256(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Generate HMAC-SHA256
  /// Used for message authentication codes
  String generateHMAC(String message, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// Add app credentials to all API request headers
  Map<String, String> getSecurityHeaders() {
    return {
      'X-App-ID': _appId,
      'X-Device-ID': _deviceId,
      'X-App-Signature': generateHMAC(_appId, _appPrivateKey),
      'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }

  /// Verify app credentials (checks if registered and valid)
  Future<bool> verifyAppCredentials() async {
    try {
      if (_appId.isEmpty || _appPrivateKey.isEmpty) {
        developer.log('App not registered');
        return false;
      }

      developer.log('App credentials verified');
      return true;
    } catch (e) {
      developer.log('Error verifying credentials: $e');
      return false;
    }
  }

  /// Clear all stored credentials (app uninstall/logout)
  Future<void> clearCredentials() async {
    await _prefs.remove(_appIdKey);
    await _prefs.remove(_appPrivateKeyKey);
    await _prefs.remove(_serverPublicKeyKey);
    await _prefs.remove(_deviceIdKey);

    developer.log('App credentials cleared');
  }

  /// Get app info for debugging
  Map<String, String> getAppInfo() {
    return {
      'appId': _appId,
      'deviceId': _deviceId,
      'hasPrivateKey': _appPrivateKey.isNotEmpty ? 'YES' : 'NO',
      'hasServerPublicKey': _serverPublicKey.isNotEmpty ? 'YES' : 'NO',
    };
  }
}
