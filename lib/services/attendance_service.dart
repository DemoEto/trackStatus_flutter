import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get attendance records for a student
  Stream<QuerySnapshot> getAttendanceForStudent(String studentId, DateTime startOfMonth, DateTime endOfMonth) {
    return _firestore
        .collection('Attendance')
        .where('studentId', isEqualTo: studentId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get attendance records for multiple students (for parent view)
  Future<List<QueryDocumentSnapshot>> getAttendanceForStudents(
    List<String> studentIds,
    DateTime startOfMonth,
    DateTime endOfMonth,
  ) async {
    List<QueryDocumentSnapshot> allDocs = [];

    // Process in batches of 10 to respect Firestore's whereIn limit
    for (int i = 0; i < studentIds.length; i += 10) {
      List<String> chunk = studentIds.skip(i).take(10).toList();
      
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('Attendance')
          .where('studentId', whereIn: chunk)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('timestamp', descending: true)
          .get();
          
      allDocs.addAll(attendanceSnapshot.docs);
    }

    // Sort all docs by timestamp descending
    allDocs.sort((a, b) {
      Map<String, dynamic>? aData = a.data() as Map<String, dynamic>?;
      Map<String, dynamic>? bData = b.data() as Map<String, dynamic>?;
      Timestamp? aTimestamp = aData?['timestamp'] as Timestamp?;
      Timestamp? bTimestamp = bData?['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp);
    });

    return allDocs;
  }

  // Submit attendance records
  Future<void> submitAttendance(List<Map<String, dynamic>> attendanceRecords) async {
    final batch = _firestore.batch();

    for (var record in attendanceRecords) {
      final ref = _firestore.collection('Attendance').doc('${record['uid']}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
      
      batch.set(ref, {
        'studentId': record['id'],
        'name': record['name'],
        'status': record['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Determine attendance status based on time
  String _determineStatus(DateTime scanTime, DateTime classStartTime) {
    Duration timeDiff = scanTime.difference(classStartTime);
    Duration allowedLateTime = const Duration(minutes: 15);
    Duration allowedAbsentTime = const Duration(minutes: 30);

    if (timeDiff.inMinutes <= allowedLateTime.inMinutes) {
      return 'present';  // On time
    } else if (timeDiff.inMinutes <= allowedAbsentTime.inMinutes) {
      return 'late';  // Late
    } else {
      return 'absent'; // Absent
    }
  }

  // Save pending attendance with time-based status logic
  Future<void> savePendingAttendance({
    required String stdId,
    required String subId,
    required String teacherId,
    DateTime? scanTime,
  }) async {
    try {
      // Get student data
      DocumentSnapshot studentDoc = await _firestore.collection('Users').doc(stdId).get();
      
      if (!studentDoc.exists) {
        throw Exception('Student with ID $stdId not found');
      }
      
      Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
      
      // Get subject data
      DocumentSnapshot subjectDoc = await _firestore.collection('Subjects').doc(subId).get();
      
      if (!subjectDoc.exists) {
        throw Exception('Subject with ID $subId not found');
      }
      
      Map<String, dynamic> subjectData = subjectDoc.data() as Map<String, dynamic>;
      
      // Get current teacher data
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Determine the status based on scan time if provided
      String status = 'present'; // default
      DateTime scanTimeToUse = scanTime ?? DateTime.now();
      String date = scanTimeToUse.toIso8601String().split('T')[0]; // YYYY-MM-DD format

      // Set class start time (assuming 08:00 AM as class start time)
      DateTime classStartTime = DateTime(
        scanTimeToUse.year,
        scanTimeToUse.month,
        scanTimeToUse.day,
        8, // Assuming class starts at 8 AM
        0,
        0,
      );

      status = _determineStatus(scanTimeToUse, classStartTime);

      // Create pending attendance record
      await _firestore.collection('PendingAttendance').add({
        'studentId': stdId,
        'studentName': studentData['name'] ?? '',
        'studentIdNumber': studentData['id'] ?? '',
        'status': status,
        'subjectId': subId,
        'subjectName': subjectData['name'] ?? '',
        'teacherId': teacherId.isNotEmpty ? teacherId : currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'scannedAt': Timestamp.fromDate(scanTimeToUse),
        'classStartTime': Timestamp.fromDate(classStartTime),
        'date': date, // YYYY-MM-DD format
        'isProcessed': false,
      });
    } catch (e) {
      print('Error saving pending attendance: $e');
      rethrow;
    }
  }

  // Get pending attendance records
  Stream<QuerySnapshot> getPendingAttendance() {
    return _firestore
        .collection('PendingAttendance')
        .where('isProcessed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get pending attendance records for a specific subject and date
  Stream<QuerySnapshot> getPendingAttendanceForSubjectDate(String subjectId, String date) {
    return _firestore
        .collection('PendingAttendance')
        .where('subjectId', isEqualTo: subjectId)
        .where('date', isEqualTo: date)
        .where('isProcessed', isEqualTo: false)
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }

  // Mark pending attendance as processed
  Future<void> markAsProcessed(String attendanceId) async {
    await _firestore.collection('PendingAttendance').doc(attendanceId).update({
      'isProcessed': true,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get attendance records by status for a specific subject and date
  Stream<QuerySnapshot> getAttendanceByStatus(String subjectId, String date, String status) {
    return _firestore
        .collection('PendingAttendance')
        .where('subjectId', isEqualTo: subjectId)
        .where('date', isEqualTo: date)
        .where('status', isEqualTo: status)
        .snapshots();
  }

  // Update the status of a pending attendance record
  Future<void> updatePendingAttendanceStatus(String attendanceId, String newStatus) async {
    await _firestore.collection('PendingAttendance').doc(attendanceId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get processed attendance for a specific subject and date
  Stream<QuerySnapshot> getProcessedAttendanceForSubjectDate(String subjectId, String date) {
    return _firestore
        .collection('PendingAttendance')
        .where('subjectId', isEqualTo: subjectId)
        .where('date', isEqualTo: date)
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }
}