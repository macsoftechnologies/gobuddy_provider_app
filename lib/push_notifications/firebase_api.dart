import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/push_notifications/push_notification_screen.dart';


/// MUST be top-level
Future<void> handlerBackgroundMessaging(RemoteMessage message) async {
  debugPrint('Background Message Title: ${message.notification?.title}');
  debugPrint('Background Message Body: ${message.notification?.body}');
  debugPrint('Background Payload: ${message.data}');
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications(BuildContext context) async {
    /// Request permission (iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $fcmToken");
    if (fcmToken != null && fcmToken.isNotEmpty) {
      Preferences.setFcmToken(fcmToken);
    }

    /// Background messages
    FirebaseMessaging.onBackgroundMessage(handlerBackgroundMessaging);

    /// Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Title: ${message.notification?.title}');
      debugPrint('Foreground Body: ${message.notification?.body}');
      debugPrint('Foreground Payload: ${message.data}');

      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>  PushNotificationScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    });

    /// App opened from terminated state
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && initialMessage.data['screen'] != null) {
      Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>  PushNotificationScreen(),
                  ),
                );
    }

    /// App opened from background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification Clicked!');
      if (message.data['screen'] != null) {
         Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>  PushNotificationScreen(),
                  ),
                );
      }
    });
  }
}
