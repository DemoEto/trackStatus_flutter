import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> savePendingAttendance({
  required String stdId,
  required String status,
  required String subId,
  required String teacherId,
}) async {
  // วันที่วันนี้เป็น string เช่น "2025-09-27"
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // อ้างอิง collection pendingAttendance
  final pendingRef = FirebaseFirestore.instance.collection('pendingAttendance');

  await pendingRef.add({
    'date': today,
    'students': [
      {
        'status': status,
        'stdId': stdId,
        'subId': subId,
        'teacherId': teacherId,
      }
    ]
  });
}
