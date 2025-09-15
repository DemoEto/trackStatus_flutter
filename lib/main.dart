import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'routes/route_config.dart'; // import GoRouter ที่คุณตั้งไว้

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBcfZoNGITsvNcnaP2TDadVAlNVIerpEaQ",
        authDomain: "trackstatus-flutter.firebaseapp.com",
        projectId: "trackstatus-flutter",
        storageBucket: "trackstatus-flutter.firebasestorage.app",
        messagingSenderId: "1005522555437",
        appId: "1:1005522555437:web:64ea9120b945db8faa1ea4",
        measurementId: "G-DB7ZL6WBPS",
      ),
    );
  }else{
    await Firebase.initializeApp();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<AuthService>.value(
//       value: authService,
//       child: MaterialApp.router(
//         title: 'TrackStatus App',
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         ),
//         routerConfig: router,
//       ),
//     );
//   }

// }

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
