import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

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

  // Update user's FCM token in Firestore
  Future<void> _updateUserTokenInFirestore(String userId, String token) async {
    try {
      await _firestore.collection('Users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user token: $e');
    }
  }

  // Update user's FCM token when they log in
  Future<void> _updateUserToken(String userId) async {
    try {
      // Setup token refresh listener for automatic updates
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        print('FCM token refreshed for user $userId: $token');
        await _updateUserTokenInFirestore(userId, token);
      }).onError((error) {
        print('Error listening for token refresh for user $userId: $error');
      });
      
      // Get current token (on iOS, this may initially fail if APNS token isn't ready)
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM token retrieved for user $userId: $token');
        await _updateUserTokenInFirestore(userId, token);
      } else {
        print('FCM token not available yet for user $userId. Waiting for token refresh.');
      }
    } catch (e) {
      print('Error updating token for user $userId: $e');
      // For iOS-specific APNS error, provide a more descriptive message
      if (e.toString().contains('apns-token-not-set')) {
        print('This error typically occurs on iOS when APNS token is not ready yet. '
            'The token refresh listener will handle the token once it becomes available.');
      }
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
