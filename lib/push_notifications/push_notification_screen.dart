import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationScreen extends StatefulWidget {
  @override
  _PushNotificationScreenState createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  List<Map<String, String>> notifications = [];

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    // Request permissions (for iOS)
    await _firebaseMessaging.requestPermission();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addNotification(message);
    });

    // When app is opened from background/terminated via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addNotification(message);
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _addNotification(initialMessage);
    }
  }

  void _addNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    setState(() {
      notifications.insert(0, {
        "title": notification?.title ?? data['title'] ?? "No Title",
        "body": notification?.body ?? data['body'] ?? "No Body",
        "time": DateTime.now().toString(),
      });
    });
  }

  String formatTime(String time) {
    DateTime dateTime = DateTime.parse(time);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No notifications yet!",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              padding: EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(
                      notif["title"]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          notif["body"]!,
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          formatTime(notif["time"]!),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
