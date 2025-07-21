import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((_) {
      notifyListeners(); // แจ้ง GoRouter ให้รีเฟรช
    });
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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
  // สมัคร
  await _firebaseAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // อัปเดต displayName
  final user = currentUser;
  await user?.updateDisplayName(displayName);

  // โหลดใหม่และอัปเดต reference
  await user?.reload();
  // 🔥 บังคับโหลด user ใหม่เข้ามา
 
  print('🔄 UserName = $currentUser');
  // แจ้งให้ และ GoRouter รู้
  notifyListeners();
}

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

// แนะนำตั้งเป็นตัวแปร global สำหรับใช้ใน router
final authService = AuthService();
