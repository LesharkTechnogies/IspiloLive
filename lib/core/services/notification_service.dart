import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Uncomment after adding to pubspec.yaml
import 'package:ispilo/model/notification_model.dart';
/// Notification service for managing notifications
class NotificationService {
  static const String _notificationCacheKey = 'cached_notifications';
  static const String _notificationSummaryCacheKey = 'notification_summary';
  static const String _lastFetchKey = 'last_notification_fetch';

  // Stream controllers
  static final StreamController<List<NotificationModel>> _notificationStreamController =
      StreamController<List<NotificationModel>>.broadcast();

  static final StreamController<NotificationSummary> _summaryStreamController =
      StreamController<NotificationSummary>.broadcast();

  // Public streams
  static Stream<List<NotificationModel>> get notificationStream => _notificationStreamController.stream;
  static Stream<NotificationSummary> get summaryStream => _summaryStreamController.stream;

  // Cleanup on app close
  static void dispose() {
    _notificationStreamController.close();
    _summaryStreamController.close();
  }

  /// Fetch all notifications for current user
  static Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await ApiService.get(
        '/notifications?page=$page&size=$size',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      final notifications = content
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache locally
      await _cacheNotifications(notifications);

      // Update stream
      _notificationStreamController.add(notifications);

      return notifications;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Return cached data if available
      return await _getCachedNotifications();
    }
  }

  /// Get unread notifications only
  static Future<List<NotificationModel>> getUnreadNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '/notifications/unread?page=$page&size=$size',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching unread notifications: $e');
      return [];
    }
  }

  /// Get notifications by type
  static Future<List<NotificationModel>> getNotificationsByType(
    NotificationType type, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final typeString = type.toString().split('.').last;
      final response = await ApiService.get(
        '/notifications/type/$typeString?page=$page&size=$size',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications by type: $e');
      return [];
    }
  }

  /// Get notification summary (unread count, etc.)
  static Future<NotificationSummary> getNotificationSummary() async {
    try {
      final response = await ApiService.get('/notifications/summary');
      final summary = NotificationSummary.fromJson(response as Map<String, dynamic>);

      // Cache summary
      await _cacheSummary(summary);

      // Update stream
      _summaryStreamController.add(summary);

      return summary;
    } catch (e) {
      debugPrint('Error fetching notification summary: $e');
      return await _getCachedSummary() ??
          NotificationSummary(
            unreadCount: 0,
            totalCount: 0,
            lastFetchTime: DateTime.now(),
            countByType: {},
          );
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await ApiService.post(
        '/notifications/$notificationId/read',
        {},
      );

      // Refresh summary
      await getNotificationSummary();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      await ApiService.post(
        '/notifications/read-all',
        {},
      );

      // Refresh notifications and summary
      await Future.wait([
        getNotifications(),
        getNotificationSummary(),
      ]);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await ApiService.delete('/notifications/$notificationId');

      // Refresh summary
      await getNotificationSummary();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      await ApiService.delete('/notifications/all');

      // Clear cache and refresh
      await _clearNotificationCache();
      await getNotifications(forceRefresh: true);
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  /// Search notifications
  static Future<List<NotificationModel>> searchNotifications(String query) async {
    try {
      final response = await ApiService.get(
        '/notifications/search?q=${Uri.encodeComponent(query)}',
      );

      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching notifications: $e');
      return [];
    }
  }

  /// Get notification by ID
  static Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final response = await ApiService.get('/notifications/$notificationId');
      return NotificationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching notification: $e');
      return null;
    }
  }

  /// Setup background notification fetching
  static Future<void> setupBackgroundFetching({
    Duration interval = const Duration(minutes: 5),
  }) async {
    // Fetch periodically
    Timer.periodic(interval, (_) async {
      await getNotificationSummary();
    });
  }

  // ============================================================================
  // PUSH NOTIFICATIONS (FCM) INTEGRATION
  // Based on Backend Specs: NEW_POST and GROUP_POST with targetId deep linking
  // ============================================================================
  
  /*
  /// Initializes Firebase Cloud Messaging to listen for push notifications
  /// Call this inside your main.dart after Firebase.initializeApp()
  static Future<void> setupPushNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permissions (primarily for iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get FCM token and register it with your backend
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        debugPrint('FCM Token: $fcmToken');
        // await ApiService.post('/users/me/fcm-token', {'token': fcmToken});
      }

      // Handle foreground notifications (Refresh local notification center instantly)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground push notification: ${message.data}');
        getNotificationSummary();
        getNotifications(forceRefresh: true);
      });

      // Handle background/terminated deep links
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationDeepLink(message.data, navigatorKey);
      });
      
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationDeepLink(initialMessage.data, navigatorKey);
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  static void _handleNotificationDeepLink(Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
    final type = data['type']?.toString();
    final targetId = data['targetId']?.toString();

    if (type == null || targetId == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'NEW_POST') {
      Navigator.pushNamed(context, '/post-content', arguments: {'postId': targetId});
    } else if (type == 'GROUP_POST') {
      // As per backend spec, navigate to the group's feed
      Navigator.pushNamed(context, '/group-profile', arguments: {'groupId': targetId});
    }
  }
  */

  /// Cache notifications locally
  static Future<void> _cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(
        _notificationCacheKey,
        jsonList.toString(),
      );
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching notifications: $e');
    }
  }

  /// Get cached notifications
  static Future<List<NotificationModel>> _getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_notificationCacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Note: In production, use proper JSON parsing
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error retrieving cached notifications: $e');
      return [];
    }
  }

  /// Cache notification summary
  static Future<void> _cacheSummary(NotificationSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _notificationSummaryCacheKey,
        summary.toJson().toString(),
      );
    } catch (e) {
      debugPrint('Error caching notification summary: $e');
    }
  }

  /// Get cached summary
  static Future<NotificationSummary?> _getCachedSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_notificationSummaryCacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Note: In production, use proper JSON parsing
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving cached summary: $e');
      return null;
    }
  }

  /// Clear notification cache
  static Future<void> _clearNotificationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationCacheKey);
      await prefs.remove(_notificationSummaryCacheKey);
      await prefs.remove(_lastFetchKey);
    } catch (e) {
      debugPrint('Error clearing notification cache: $e');
    }
  }
}
