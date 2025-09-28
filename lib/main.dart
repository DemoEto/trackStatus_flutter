import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart'; // Firebase configuration
import 'routes/route_config.dart'; // import GoRouter ที่คุณตั้งไว้
import 'services/notification_service.dart'; // import Notification service
import 'services/user_service.dart'; // import UserService
import 'theme/app_theme.dart'; // import the new app theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for locale support
  await initializeDateFormatting();
  
  // Initialize Firebase with proper duplicate app handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('Firebase app already exists, using existing app');
      // Don't rethrow for duplicate app - this is expected behavior in some cases
    } else {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initializePlatformNotifications();
  print('Notification service initialized');
  
  await notificationService.requestNotificationPermission();
  print('Notification permission requested');
  
  notificationService.handleNotificationStream();
  print('Notification stream handled');

  // Initialize attendance notification service
  final userService = UserService();
  userService.startAttendanceNotificationService(); // Remove await since the method returns void // Add await here
  print('User service initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrackStatus App',
      theme: AppTheme.theme, // Use the new app theme
      routerConfig: router, // ✅ ใช้ GoRouter ที่คุณตั้งไว้
    );
  }
}
