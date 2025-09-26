// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static Future<void> addPendingAttendance(String studentUid) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(studentUid)
        .get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final ref = FirebaseFirestore.instance
        .collection('PendingAttendance')
        .doc('${studentUid}_$today');

    await ref.set({
      'studentId': data['stdId'],
      'name': data['name'],
      'uid': studentUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
