import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/route_config.dart'; // import GoRouter ที่คุณตั้งไว้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
