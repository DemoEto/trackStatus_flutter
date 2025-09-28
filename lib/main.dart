import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackstatus_flutter/services/notification_service.dart';

import 'firebase_options.dart'; // Firebase configuration
import 'routes/route_config.dart'; // import GoRouter ที่คุณตั้งไว้
import 'services/notification_service.dart'; // import Notification service
import 'services/user_service.dart'; // import UserService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  notificationService.initializePlatformNotifications();
  notificationService.requestNotificationPermission();
  notificationService.handleNotificationStream();

  // Initialize attendance notification service
  final userService = UserService();
  userService.startAttendanceNotificationService(); // Remove await since the method returns void // Add await here

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrackStatus App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router, // ✅ ใช้ GoRouter ที่คุณตั้งไว้
    );
  }
}
