import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Encryption service for AES-256-GCM message encryption in Flutter
class EncryptionService {
  static const String algorithm = 'AES-256-GCM';
  static const int keySize = 32; // 256 bits
  static const int ivSize = 12; // 96 bits (12 bytes) for GCM
  static const int tagSize = 128; // 128 bits (16 bytes) for GCM tag

  /// Encrypt message using AES-256-GCM
  /// Returns map with 'encrypted' and 'iv' as Base64 strings
  Map<String, String> encryptAES256GCM(String plaintext, String keyBase64) {
    try {
      // Decode key from Base64
      final keyBytes = base64Decode(keyBase64);
      if (keyBytes.length != keySize) {
        throw ArgumentError('Invalid key size: ${keyBytes.length} bytes');
      }

      // Generate random IV (12 bytes for GCM)
      final random = _getSecureRandom();
      final iv = random.nextBytes(ivSize);

      // Create cipher
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true, // encrypt mode
          AEADParameters(
            KeyParameter(keyBytes),
            tagSize,
            iv,
            Uint8List(0), // No additional authenticated data
          ),
        );

      // Encrypt plaintext
      final plaintextBytes = utf8.encode(plaintext);
      final ciphertextWithTag = cipher.process(plaintextBytes);

      // Return IV + ciphertext as Base64
      final ivBase64 = base64Encode(iv);
      final ciphertextBase64 = base64Encode(ciphertextWithTag);

      return {
        'encrypted': ciphertextBase64,
        'iv': ivBase64,
      };
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt message using AES-256-GCM
  String decryptAES256GCM(
    String encryptedBase64,
    String ivBase64,
    String keyBase64,
  ) {
    try {
      // Decode inputs from Base64
      final keyBytes = base64Decode(keyBase64);
      final ivBytes = base64Decode(ivBase64);
      final ciphertextWithTag = base64Decode(encryptedBase64);

      // Validate key and IV sizes
      if (keyBytes.length != keySize) {
        throw ArgumentError('Invalid key size: ${keyBytes.length} bytes');
      }
      if (ivBytes.length != ivSize) {
        throw ArgumentError('Invalid IV size: ${ivBytes.length} bytes');
      }

      // Create cipher for decryption
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false, // decrypt mode
          AEADParameters(
            KeyParameter(keyBytes),
            tagSize,
            ivBytes,
            Uint8List(0),
          ),
        );

      // Decrypt
      final plaintext = cipher.process(ciphertextWithTag);

      return utf8.decode(plaintext);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate a new AES-256 key
  String generateKey() {
    try {
      final random = _getSecureRandom();
      final keyBytes = random.nextBytes(keySize);

      return base64Encode(keyBytes);
    } catch (e) {
      throw Exception('Key generation failed: $e');
    }
  }

  /// Generate random IV for one-time use
  String generateIV() {
    try {
      final random = _getSecureRandom();
      final ivBytes = random.nextBytes(ivSize);

      return base64Encode(ivBytes);
    } catch (e) {
      throw Exception('IV generation failed: $e');
    }
  }

  /// Hash a string using SHA-256
  String hashSHA256(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Hash a string using SHA-512
  String hashSHA512(String input) {
    return sha512.convert(utf8.encode(input)).toString();
  }

  /// Verify encrypted message integrity
  bool verifyMessageIntegrity(
    String encryptedBase64,
    String ivBase64,
    String expectedHash,
  ) {
    try {
      final combined = '$encryptedBase64:$ivBase64';
      final actualHash = hashSHA256(combined);

      return actualHash == expectedHash;
    } catch (e) {
      print('Integrity verification error: $e');
      return false;
    }
  }
  /// Get secure random generator
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Encode string to Base64
  static String encodeBase64(String input) {
    return base64Encode(utf8.encode(input));
  }

  /// Decode Base64 to string
  static String decodeBase64(String encoded) {
    return utf8.decode(base64Decode(encoded));
  }

  /// Generate HMAC-SHA256 for message authentication
  String generateHMAC(String message, String keyBase64) {
    try {
      final keyBytes = base64Decode(keyBase64);
      final messageBytes = utf8.encode(message);

      // Using crypto package's Hmac
      final hmac = _hmacSha256(messageBytes, keyBytes);
      return base64Encode(hmac);
    } catch (e) {
      throw Exception('HMAC generation failed: $e');
    }
  }

  /// Simple HMAC-SHA256 implementation
  List<int> _hmacSha256(List<int> message, List<int> key) {
    // For production, use pointycastle or crypto package properly
    // This is a simplified version for demonstration
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).bytes;
  }
}

/// Extended encryption utilities
extension EncryptionExtension on String {
  /// Encrypt this string
  Map<String, String> encryptAES256GCM(String keyBase64) {
    return EncryptionService().encryptAES256GCM(this, keyBase64);
  }

  /// Hash this string with SHA256
  String hashSHA256() {
    return EncryptionService().hashSHA256(this);
  }

  /// Hash this string with SHA512
  String hashSHA512() {
    return EncryptionService().hashSHA512(this);
  }

  /// Encode to Base64
  String toBase64() {
    return EncryptionService.encodeBase64(this);
  }
}

/// Message encryption helper
class MessageEncryption {
  final String plaintext;
  final String conversationKey;
  final EncryptionService encryptionService;

  MessageEncryption({
    required this.plaintext,
    required this.conversationKey,
    EncryptionService? encryptionService,
  }) : encryptionService = encryptionService ?? EncryptionService();

  /// Encrypt and return full encrypted message object
  EncryptedMessage encrypt() {
    final encrypted = encryptionService.encryptAES256GCM(
      plaintext,
      conversationKey,
    );

    return EncryptedMessage(
      encryptedContent: encrypted['encrypted']!,
      encryptionIv: encrypted['iv']!,
      encryptionAlgorithm: EncryptionService.algorithm,
      plaintext: plaintext, // Keep plaintext for immediate display
    );
  }

  /// Create HMAC for message authentication
  String createAuthenticationTag() {
    return encryptionService.generateHMAC(plaintext, conversationKey);
  }
}

/// Encrypted message data class
class EncryptedMessage {
  final String encryptedContent;
  final String encryptionIv;
  final String encryptionAlgorithm;
  final String plaintext; // Keep plaintext for UI display

  EncryptedMessage({
    required this.encryptedContent,
    required this.encryptionIv,
    required this.encryptionAlgorithm,
    required this.plaintext,
  });

  /// Convert to JSON for sending over WebSocket
  Map<String, dynamic> toJson() {
    return {
      'encryptedContent': encryptedContent,
      'encryptionIv': encryptionIv,
      'encryptionAlgorithm': encryptionAlgorithm,
      'isEncrypted': true,
    };
  }

  /// Decrypt this message
  static String decrypt(
    EncryptedMessage message,
    String conversationKey,
  ) {
    return EncryptionService().decryptAES256GCM(
      message.encryptedContent,
      message.encryptionIv,
      conversationKey,
    );
  }
}

/// Key management utilities
class KeyManagement {
  static const String _keyStoragePrefix = 'encryption_key_';

  /// Generate and store conversation key securely
  static Future<String> generateAndStoreConversationKey(
    String conversationId,
  ) async {
    final key = EncryptionService().generateKey();
    // TODO: Store in secure storage (flutter_secure_storage)
    return key;
  }

  /// Retrieve conversation key from secure storage
  static Future<String?> retrieveConversationKey(String conversationId) async {
    // TODO: Retrieve from flutter_secure_storage
    return null;
  }

  /// Rotate conversation key (call every 90 days)
  static Future<String> rotateConversationKey(String conversationId) async {
    final newKey = EncryptionService().generateKey();
    // TODO: Store new key and notify other participants
    return newKey;
  }

  /// Clear stored keys (on logout)
  static Future<void> clearAllKeys() async {
    // TODO: Clear all keys from secure storage
  }
}
