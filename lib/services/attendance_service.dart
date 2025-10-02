import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  // Get all attendance records
  Stream<QuerySnapshot> getAllAttendanceRecords() {
    return _firestore.collection('Attendance').snapshots();
  }

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

  // Add a new attendance record (handles both uses from different pages)
  Future<void> addAttendance({
    required String studentId,
    required String name,
    String? subId,
    String? subjectId,
    String? type,
    required String status,
    String? teacherId,
    DateTime? timestamp,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use provided timestamp or get current timestamp
      Timestamp firestoreTimestamp = timestamp != null 
          ? Timestamp.fromDate(timestamp) 
          : Timestamp.now();

      // Use either subId or subjectId (for different calling pages)
      String usedSubId = subId ?? subjectId ?? "";
      
      // Create attendance document
      String attendanceId = "${studentId}_${usedSubId}_${firestoreTimestamp.millisecondsSinceEpoch}";
      Map<String, dynamic> attendanceData = {
        'studentId': studentId,
        'name': name,
        'status': status,
        'timestamp': firestoreTimestamp,
        if (subId != null) 'subId': subId,
        if (subjectId != null) 'subjectId': subjectId,
        if (type != null) 'type': type,
        if (teacherId != null) 'teacherId': teacherId,
      };
      
      await _firestore.collection('Attendance').doc(attendanceId).set(attendanceData);

      // Send notifications to student and their parents
      await _sendAttendanceNotifications(
        studentId: studentId,
        subId: usedSubId,
        status: status,
        timestamp: firestoreTimestamp,
        teacherId: teacherId ?? user.uid,
      );
    } catch (e) {
      print('Error adding attendance: $e');
      rethrow;
    }
  }

  // Send attendance notifications to student and parents
  Future<void> _sendAttendanceNotifications({
    required String studentId,
    required String subId,
    required String status,
    required Timestamp timestamp,
    required String teacherId,
  }) async {
    try {
      // Get student's device token to send push notification using UserService
      Map<String, dynamic>? studentData = await _userService.getUserById(studentId);
      String? deviceToken = studentData?['fcmToken'] as String?;

      // Create notification title and body based on status
      String title, body;
      
      switch (status) {
        case 'present':
          title = 'การมาเรียน';
          body = 'คุณมาเรียนวิชา $subId แล้ว';
          break;
        case 'leave':
          title = 'การลาเรียน';
          body = 'คุณได้รับอนุญาตให้ลากิจวิชา $subId';
          break;
        case 'absent':
          title = 'การขาดเรียน';
          body = 'คุณขาดเรียนวิชา $subId';
          break;
        default:
          title = 'อัปเดตสถานะการมาเรียน';
          body = 'มีการอัปเดตสถานะการมาเรียนวิชา $subId';
      }

      // Create a Firestore notification for the student
      String notificationId = await _notificationService.createFirestoreNotification(
        title: title,
        body: body,
        type: 'attendance_update',
        senderId: teacherId,
        senderName: 'ระบบ',
        recipientId: studentId,
        payload: {
          'subject': subId,
          'status': status,
          'timestamp': timestamp.toDate().toString(),
        },
      );

      // Send push notification to the student if device token is available
      if (deviceToken != null) {
        await _notificationService.sendPushNotification(
          deviceToken: deviceToken,
          title: title,
          body: body,
          data: {
            'type': 'attendance_update',
            'notificationId': notificationId,
            'subject': subId,
            'status': status,
          },
        );
      }

      // Find parents of this student and send notification using UserService
      QuerySnapshot? parentSnapshot;
      await for (var snapshot in _userService.getParentsByChildId(studentId)) {
        parentSnapshot = snapshot;
        break; // Get the first snapshot
      }

      if (parentSnapshot != null) {
        for (var parentDoc in parentSnapshot.docs) {
          String parentTitle, parentBody;
          
          switch (status) {
            case 'present':
              parentTitle = 'แจ้งเตือนการมาเรียน';
              parentBody = 'นักเรียน $studentId เข้าเรียนวิชา $subId แล้ว';
              break;
            case 'leave':
              parentTitle = 'แจ้งเตือนการลา';
              parentBody = 'นักเรียน $studentId ได้ทำการลาเรียนวิชา $subId';
              break;
            case 'absent':
              parentTitle = 'แจ้งเตือนการขาดเรียน';
              parentBody = 'นักเรียน $studentId ขาดเรียนวิชา $subId';
              break;
            default:
              parentTitle = 'อัปเดตสถานะการมาเรียน';
              parentBody = 'นักเรียน $studentId มีการอัปเดตสถานะการมาเรียนวิชา $subId';
          }

          // Get parent's device token to send push notification
          String? parentDeviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String parentNotificationId = await _notificationService.createFirestoreNotification(
            title: parentTitle,
            body: parentBody,
            type: 'attendance_update',
            senderId: teacherId,
            senderName: 'ระบบ',
            recipientId: parentDoc.id,
            payload: {
              'studentId': studentId,
              'subject': subId,
              'status': status,
              'timestamp': timestamp.toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (parentDeviceToken != null) {
            await _notificationService.sendPushNotification(
              deviceToken: parentDeviceToken,
              title: parentTitle,
              body: parentBody,
              data: {
                'type': 'attendance_update',
                'notificationId': parentNotificationId,
                'studentId': studentId,
                'subject': subId,
                'status': status,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error sending attendance notifications: $e');
      rethrow;
    }
  }

  // Update an existing attendance record
  Future<void> updateAttendance({
    required String attendanceId,
    String? studentId,
    String? name,
    String? subId,
    String? type,
    String? status,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (studentId != null) updateData['studentId'] = studentId;
      if (name != null) updateData['name'] = name;
      if (subId != null) updateData['subId'] = subId;
      if (type != null) updateData['type'] = type;
      if (status != null) updateData['status'] = status;
      updateData['timestamp'] = FieldValue.serverTimestamp();

      await _firestore.collection('Attendance').doc(attendanceId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating attendance: $e');
      rethrow;
    }
  }

  // Delete an attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _firestore.collection('Attendance').doc(attendanceId).delete();
    } catch (e) {
      print('Error deleting attendance: $e');
      rethrow;
    }
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
      // Get student data using UserService
      Map<String, dynamic>? studentData = await _userService.getUserById(stdId);
      
      if (studentData == null) {
        throw Exception('Student with ID $stdId not found');
      }
      
      // Get subject data - for now, we'll need to handle this separately
      // For now, we'll just use the subId as subjectName until subject service is implemented
      String subjectName = subId; // This would come from a subject service
      
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
        'subjectName': subjectName,
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