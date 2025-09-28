import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/notification_helper.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  User? get currentUser =>
      _firebaseAuth.currentUser; // !-- currentUser = null for sure

  AuthService() {
    _firebaseAuth.authStateChanges().listen((user) {
      // When user logs in, update their FCM token
      if (user != null) {
        _updateUserToken(user.uid);
      }
      notifyListeners(); // แจ้ง GoRouter ให้รีเฟรช
    });
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.get('role') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Update user's FCM token when they log in
  Future<void> _updateUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await NotificationHelper.updateUserToken(userId, token);
      }
    } catch (e) {
      print('Error updating token for user $userId: $e');
    }
  }

  Future<void> signIn({required String email, password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // สมัคร
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // อัปเดต displayName
      await userCredential.user?.updateDisplayName(displayName);

      // โหลดใหม่และอัปเดต reference
      await userCredential.user?.reload();
      // 🔥 บังคับโหลด user ใหม่เข้ามา
      User? updatedUser = FirebaseAuth.instance.currentUser;
      
      // Update FCM token for new user
      if (updatedUser != null) {
        await _updateUserToken(updatedUser.uid);
      }
      
      // แจ้งให้ทุกอย่างรู้
      notifyListeners();

      print('✅ Registered user: ${updatedUser?.displayName}');
    } catch (e) {
      print('\n❌ Register Error: ${e.toString()}\n');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
    notifyListeners(); // จะทำให้ GoRouter รีโหลดด้วย
  }
}

// แนะนำตั้งเป็นตัวแปร global สำหรับใช้ใน router
final authService = AuthService();
