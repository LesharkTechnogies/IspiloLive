import 'package:flutter/foundation.dart';

/// Tracks API deprecation/upgrade hints from response headers.
class ApiVersionNotifier {
  ApiVersionNotifier._();
  static final ApiVersionNotifier instance = ApiVersionNotifier._();

  /// Whether the backend signaled this client is deprecated.
  final ValueNotifier<bool> deprecated = ValueNotifier<bool>(false);

  /// Suggested upgrade path (e.g., /api/v2) if provided.
  final ValueNotifier<String?> upgradeTo = ValueNotifier<String?>(null);

  /// Update state from response headers.
  void updateFromHeaders(Map<String, String> headers) {
    final dep = headers['x-api-deprecated'] ?? headers['X-API-Deprecated'];
    final upgrade = headers['x-api-upgrade-to'] ?? headers['X-API-Upgrade-To'];

    final bool isDeprecated = dep?.toLowerCase() == 'true';
    if (deprecated.value != isDeprecated) {
      deprecated.value = isDeprecated;
    }

    final trimmedUpgrade = upgrade?.trim();
    if (upgradeTo.value != trimmedUpgrade) {
      upgradeTo.value = trimmedUpgrade?.isEmpty == true ? null : trimmedUpgrade;
    }
  }
}
