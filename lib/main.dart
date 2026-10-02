import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/push_notifications/firebase_api.dart';
import 'package:gobuddy/routes/my_app_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Optional but recommended to avoid redraw warnings
  WidgetsBinding.instance.deferFirstFrame();

  await Firebase.initializeApp();
  await Preferences.initSharedPreference();

  WidgetsBinding.instance.allowFirstFrame();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    /// Ensures context & navigator are fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseApi().initNotifications(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MyAppRoute(); // Your existing routing widget
  }
}
