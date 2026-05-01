import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // added kIsWeb

import '../../main.dart'; // To access globalNavigatorKey
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    if (kIsWeb) {
      log('Push notifications are not fully configured for web yet. Skipping.');
      return;
    }
    
    try {
      // 2. Request permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('User granted permission: ${settings.authorizationStatus}');

      // 3. Get FCM token
      String? token = await _firebaseMessaging.getToken();
      log('FCM Token: $token');
      if (token != null) {
        await ApiService.updateFcmToken(token);
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token Refreshed: $newToken');
        await ApiService.updateFcmToken(newToken);
      });

      // 4. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Handle messages while app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log('Message also contained a notification: ${message.notification}');
          // Optionally show a local notification or snackbar here
        }
      });

      // 6. Handle app opening from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // 7. Handle app opening from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message);
      });
    } catch (e) {
      log('Error initializing PushNotificationService: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    log('Handling message tap: ${message.data}');
    final type = message.data['type'];
    final targetId = message.data['targetId'];

    if (type == 'NEW_POST') {
      // Navigate to post details
      // Since postData requires full post object, we might just pass empty strings
      // or ideally fetch it from API. Here we navigate and pass targetId.
      globalNavigatorKey.currentState?.pushNamed('/post-content', arguments: {
        'id': targetId,
        'content': 'Post ID: $targetId (Fetch actual content via API)',
        'username': 'Notification',
      });
    } else if (type == 'GROUP_POST') {
      // Navigate to group feed
      globalNavigatorKey.currentState?.pushNamed('/group-profile', arguments: {
        'groupId': targetId,
        'groupName': 'Group'
      });
    }
  }
}
