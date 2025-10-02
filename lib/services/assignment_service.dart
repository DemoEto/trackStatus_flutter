import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get assignmentsCollection => _firestore.collection('Assignments');

  // Check for assignments due soon and send reminders
  Future<void> checkForAssignmentReminders() async {
    try {
      final now = Timestamp.now();
      final threeDaysFromNow = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      );

      // Get assignments due in the next 3 days that haven't been submitted yet
      QuerySnapshot assignmentsSnapshot = await assignmentsCollection
          .where('dueDate', isLessThanOrEqualTo: threeDaysFromNow)
          .where('dueDate', isGreaterThanOrEqualTo: now)
          .get();

      for (var assignmentDoc in assignmentsSnapshot.docs) {
        Map<String, dynamic> assignment = assignmentDoc.data() as Map<String, dynamic>;
        
        // Get the students assigned to this assignment
        List<dynamic> assignedStudentIds = assignment['assignedStudentIds'] as List<dynamic>;
        
        for (String studentId in assignedStudentIds.cast<String>()) {
          // Check if student has already submitted
          DocumentSnapshot submissionDoc = await assignmentsCollection
              .doc(assignmentDoc.id)
              .collection('Submissions')
              .doc(studentId)
              .get();
              
          if (!submissionDoc.exists) {
            // Student hasn't submitted yet, send reminder
            int daysUntilDue = assignment['dueDate'].toDate().difference(DateTime.now()).inDays;
            
            final notificationService = NotificationService();

            // Get the student's device token to send push notification
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(studentId)
                .get();

            String? deviceToken = userDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the student
            String notificationId = await notificationService.createFirestoreNotification(
              title: 'แจ้งเตือนการบ้านใกล้ถึงกำหนดส่ง',
              body: 'การบ้าน "${assignment['title'] as String}" ในวิชา "${assignment['subjectId'] as String}" จะถึงกำหนดส่งในอีก $daysUntilDue วัน',
              type: 'deadline_reminder',
              senderId: 'system',
              senderName: 'ระบบ',
              recipientId: studentId,
              payload: {
                'assignmentId': assignment['id'] as String,
                'studentId': studentId,
                'studentName': await _getStudentName(studentId),
                'assignmentTitle': assignment['title'] as String,
                'subjectName': assignment['subjectId'] as String,
                'dueDate': assignment['dueDate'].toDate().toIso8601String(),
                'daysRemaining': daysUntilDue,
              },
            );

            // Send push notification to the student if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: 'แจ้งเตือนการบ้านใกล้ถึงกำหนดส่ง',
                body: 'การบ้าน "${assignment['title'] as String}" ในวิชา "${assignment['subjectId'] as String}" จะถึงกำหนดส่งในอีก $daysUntilDue วัน',
                data: {
                  'type': 'deadline_reminder',
                  'notificationId': notificationId,
                  'assignmentId': assignment['id'] as String,
                  'studentId': studentId,
                  'daysRemaining': daysUntilDue,
                },
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for assignment reminders: $e');
    }
  }

  // Helper method to get student name
  Future<String> _getStudentName(String studentId) async {
    try {
      DocumentSnapshot studentDoc = await _firestore.collection('Users').doc(studentId).get();
      return studentDoc.get('name') as String? ?? 'นักเรียน';
    } catch (e) {
      print('Error getting student name: $e');
      return 'นักเรียน';
    }
  }

  // Check for overdue assignments and send notifications
  Future<void> checkForOverdueAssignments() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      // Get assignments that are overdue
      QuerySnapshot assignmentsSnapshot = await assignmentsCollection
          .where('dueDate', isLessThan: now)
          .get();

      for (var assignmentDoc in assignmentsSnapshot.docs) {
        Map<String, dynamic> assignment = assignmentDoc.data() as Map<String, dynamic>;
        
        // Get the students assigned to this assignment
        List<dynamic> assignedStudentIds = assignment['assignedStudentIds'] as List<dynamic>;
        
        for (String studentId in assignedStudentIds.cast<String>()) {
          // Check if student has already submitted
          DocumentSnapshot submissionDoc = await assignmentsCollection
              .doc(assignmentDoc.id)
              .collection('Submissions')
              .doc(studentId)
              .get();
              
          if (!submissionDoc.exists) {
            // Student hasn't submitted yet, send overdue notification
            final notificationService = NotificationService();

            // Get the student's device token to send push notification
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(studentId)
                .get();

            String? deviceToken = userDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the student
            String notificationId = await notificationService.createFirestoreNotification(
              title: 'การบ้านค้างส่ง',
              body: 'การบ้าน "${assignment['title'] as String}" ในวิชา "${assignment['subjectId'] as String}" ค้างส่งแล้ว',
              type: 'assignment_overdue',
              senderId: 'system',
              senderName: 'ระบบ',
              recipientId: studentId,
              payload: {
                'assignmentId': assignment['id'] as String,
                'studentId': studentId,
                'studentName': await _getStudentName(studentId),
                'assignmentTitle': assignment['title'] as String,
                'subjectName': assignment['subjectId'] as String,
                'dueDate': assignment['dueDate'].toDate().toIso8601String(),
              },
            );

            // Send push notification to the student if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: 'การบ้านค้างส่ง',
                body: 'การบ้าน "${assignment['title'] as String}" ในวิชา "${assignment['subjectId'] as String}" ค้างส่งแล้ว',
                data: {
                  'type': 'assignment_overdue',
                  'notificationId': notificationId,
                  'assignmentId': assignment['id'] as String,
                  'studentId': studentId,
                },
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for overdue assignments: $e');
    }
  }

  // Create a new assignment
  Future<void> createAssignment({
    required String title,
    required String description,
    required DateTime dueDate,
    required List<String> assignedStudentIds,
    required String subjectId,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      final notificationService = NotificationService();

      // Create assignment document
      String assignmentId = assignmentsCollection.doc().id;
      await assignmentsCollection.doc(assignmentId).set({
        'id': assignmentId,
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedDate': Timestamp.now(),
        'teacherId': teacherId,
        'teacherName': teacherName,
        'subjectId': subjectId,
        'assignedStudentIds': assignedStudentIds,
        'status': 'assigned',
      });

      // Send notifications to assigned students and their parents
      for (String studentId in assignedStudentIds) {
        // Get student's device token to send push notification
        DocumentSnapshot studentDoc = await _firestore.collection('Users').doc(studentId).get();
        String? deviceToken = studentDoc.get('fcmToken') as String?;

        // Create a Firestore notification for the student
        String notificationId = await notificationService.createFirestoreNotification(
          title: 'ได้รับการบ้านใหม่',
          body: 'คุณได้รับการบ้าน "$title" วิชา $subjectId โดยคุณครู $teacherName',
          type: 'homework_assigned',
          senderId: teacherId,
          senderName: teacherName,
          recipientId: studentId,
          payload: {
            'assignmentId': assignmentId,
            'assignmentTitle': title,
            'assignmentDescription': description,
            'dueDate': dueDate.toIso8601String(),
            'subjectId': subjectId,
            'teacherId': teacherId,
            'teacherName': teacherName,
          },
        );

        // Send push notification to the student if device token is available
        if (deviceToken != null) {
          await notificationService.sendPushNotification(
            deviceToken: deviceToken,
            title: 'ได้รับการบ้านใหม่',
            body: 'คุณได้รับการบ้าน "$title" วิชา $subjectId โดยคุณครู $teacherName',
            data: {
              'type': 'homework_assigned',
              'notificationId': notificationId,
              'assignmentId': assignmentId,
              'assignmentTitle': title,
            },
          );
        }

        // Also notify parents of this student
        QuerySnapshot parentSnapshot = await _firestore
            .collection('Users')
            .where('role', isEqualTo: 'parent')
            .get();
            
        for (var parentDoc in parentSnapshot.docs) {
          List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
          if (children != null && children.contains(studentId)) {
            String? parentDeviceToken = parentDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the parent
            String parentNotificationId = await notificationService.createFirestoreNotification(
              title: 'การบ้านใหม่สำหรับลูกของคุณ',
              body: 'ลูกของคุณได้รับการบ้าน "$title" วิชา $subjectId โดยคุณครู $teacherName',
              type: 'homework_assigned',
              senderId: teacherId,
              senderName: teacherName,
              recipientId: parentDoc.id,
              payload: {
                'assignmentId': assignmentId,
                'assignmentTitle': title,
                'assignmentDescription': description,
                'studentId': studentId,
                'studentName': studentDoc.get('name') ?? 'นักเรียน',
                'dueDate': dueDate.toIso8601String(),
                'subjectId': subjectId,
                'teacherId': teacherId,
                'teacherName': teacherName,
              },
            );

            // Send push notification to the parent if device token is available
            if (parentDeviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: parentDeviceToken,
                title: 'การบ้านใหม่สำหรับลูกของคุณ',
                body: 'ลูกของคุณได้รับการบ้าน "$title" วิชา $subjectId โดยคุณครู $teacherName',
                data: {
                  'type': 'homework_assigned',
                  'notificationId': parentNotificationId,
                  'assignmentId': assignmentId,
                  'assignmentTitle': title,
                  'studentId': studentId,
                },
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error creating assignment: $e');
      rethrow;
    }
  }

  // Submit homework for a student
  Future<void> submitHomework({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String teacherId,
    required String assignmentTitle,
  }) async {
    try {
      // Update assignment status for this student
      await assignmentsCollection
          .doc(assignmentId)
          .collection('Submissions')
          .doc(studentId)
          .set({
            'studentId': studentId,
            'assignmentId': assignmentId,
            'submittedAt': Timestamp.now(),
            'status': 'submitted',
          });

      // Use NotificationService to send notification to the teacher
      final notificationService = NotificationService();
      
      // Get teacher's device token to send push notification
      DocumentSnapshot teacherDoc = await _firestore.collection('Users').doc(teacherId).get();
      String? deviceToken = teacherDoc.get('fcmToken') as String?;

      // Create a Firestore notification for the teacher
      String notificationId = await notificationService.createFirestoreNotification(
        title: 'การบ้านถูกส่งแล้ว',
        body: 'นักเรียน $studentName ได้ส่งการบ้าน "$assignmentTitle" เรียบร้อยแล้ว',
        type: 'homework_submitted',
        senderId: studentId,
        senderName: studentName,
        recipientId: teacherId,
        payload: {
          'assignmentId': assignmentId,
          'assignmentTitle': assignmentTitle,
          'studentId': studentId,
          'studentName': studentName,
          'submittedAt': Timestamp.now().toDate().toIso8601String(),
        },
      );

      // Send push notification to the teacher if device token is available
      if (deviceToken != null) {
        await notificationService.sendPushNotification(
          deviceToken: deviceToken,
          title: 'การบ้านถูกส่งแล้ว',
          body: 'นักเรียน $studentName ได้ส่งการบ้าน "$assignmentTitle" เรียบร้อยแล้ว',
          data: {
            'type': 'homework_submitted',
            'notificationId': notificationId,
            'assignmentId': assignmentId,
            'studentId': studentId,
          },
        );
      }
    } catch (e) {
      print('Error submitting homework: $e');
      rethrow;
    }
  }

  // Get assignments for current user
  Stream<List<QueryDocumentSnapshot>> getUserAssignments() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return assignmentsCollection
        .where('assignedStudentIds', arrayContains: user.uid)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}