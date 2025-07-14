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

  Future<void> signIn({required String email, required String password}) async {
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
  // 1. สร้างบัญชี
  UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // 2. อัปเดตชื่อ
  await userCredential.user!.updateDisplayName(displayName);

  // 3. โหลดข้อมูลใหม่
  await userCredential.user!.reload();
}

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

// แนะนำตั้งเป็นตัวแปร global สำหรับใช้ใน router
final authService = AuthService();
