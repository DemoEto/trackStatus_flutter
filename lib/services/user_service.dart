import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Users');

  /// ดึง user ตาม uid
  Future<StudentData?> getUserById(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return StudentData.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// ดึง user แบบ real-time (Stream)
  Stream<StudentData?> streamUser(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return StudentData.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // กรณีอยากได้ role โดยเฉพาะ
  Stream<String?> streamUserRole() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['role'] as String?);
  }
}
