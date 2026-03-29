import 'package:flutter/foundation.dart' show debugPrint;
import 'api_service.dart';

class VersionService {
  /// Fetch version metadata from backend. Non-blocking and safe for app launch.
  /// Expected payload: { min_build, latest_build, force_update, update_url }
  static Future<Map<String, dynamic>?> fetch() async {
    try {
      final data = await ApiService.fetchRemoteVersion();
      return data;
    } catch (e) {
      debugPrint('VersionService.fetch failed: $e');
      return null;
    }
  }

  /// Convenience: fetch and log. UI can later act on the result if needed.
  static Future<void> checkAndLog() async {
    // Always log fingerprint headers so we can see platform/version in console
    try {
      final headers = await ApiService.getHeaders(includeAuth: false);
      debugPrint('Fingerprint headers -> X-Platform: ${headers['X-Platform']}, X-App-Version: ${headers['X-App-Version']}, X-Build-Number: ${headers['X-Build-Number']}');
    } catch (e) {
      debugPrint('Fingerprint header fetch failed: $e');
    }

    // Then fetch remote version info (non-blocking behavior)
    final info = await fetch();
    if (info != null) {
      debugPrint('Version info: $info');
    }
  }
}
