import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('Users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['role'];
    }
    return null;
  }

  Stream<String?> streamUserRole() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore.collection('Users').doc(user.uid).snapshots().map(
      (snapshot) => snapshot.data()?['role'] as String?,
    );
  }
}
