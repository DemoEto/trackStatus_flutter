import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser =>
      _firebaseAuth.currentUser; // !-- currentUser = null for sure

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
