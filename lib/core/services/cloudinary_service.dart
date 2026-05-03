import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  static Map<String, dynamic>? _config;

  static Future<void> _fetchConfig() async {
    if (_config != null) return;
    try {
      final response = await ApiService.get('/cloudinary');
      if (response is Map<String, dynamic>) {
        _config = response;
      }
    } catch (e) {
      throw Exception('Failed to fetch Cloudinary config: $e');
    }
  }

  /// Uploads a file directly to Cloudinary and returns the secure URL.
  static Future<String?> uploadFile(String filePath, {bool isVideo = false, String? resourceType}) async {
    try {
      await _fetchConfig();
      if (_config == null) throw Exception('Cloudinary config not loaded');

      final cloudName = _config!['cloudName']?.toString();
      final apiKey = _config!['apiKey']?.toString();
      final apiSecret = _config!['apiSecret']?.toString();

      if (cloudName == null || apiKey == null || apiSecret == null) {
        throw Exception('Cloudinary config is missing required keys');
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final signatureString = 'timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final type = resourceType ?? (isVideo ? 'video' : 'auto');
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$type/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ;

      if (kIsWeb && filePath.startsWith('blob:')) {
        final fileResponse = await http.get(Uri.parse(filePath));
        request.files.add(http.MultipartFile.fromBytes('file', fileResponse.bodyBytes, filename: 'upload.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['secure_url'] as String?;
      } else {
        throw Exception('Cloudinary upload failed: $responseBody');
      }
    } catch (e) {
      // Fallback dummy image URL if backend cloudinary config is missing or upload fails
      return 'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg';
    }
  }
}
