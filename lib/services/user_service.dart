import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<StudentData?> fetchStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      return StudentData(
        name: data['name'],
        role: data['role'],
        busId: data['busId'],
        stdId: data['stdId'],
      );
    }
    return null;
  }

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
