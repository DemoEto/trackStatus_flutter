import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String? token = userDoc.get('fcmToken') as String?;
        if (token != null) {
          await _sendToDevice(token, title, body, data);
        } else {
          debugPrint('No FCM token found for user: $userId');
        }
      }
      
      // Also create a record in Firestore notifications
      String type = data?['type'] ?? 'general';
      await createFirestoreNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        payload: data,
      );
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }

  // Send notification to users by role
  static Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: role)
          .get();

      for (var userDoc in usersSnapshot.docs) {
        String? token = userDoc.get('fcmToken') as String?;
        if (token != null) {
          await _sendToDevice(token, title, body, data);
        }
        
        // Also create a record in Firestore notifications
        String type = data?['type'] ?? 'general';
        await createFirestoreNotification(
          userId: userDoc.id,
          title: title,
          body: body,
          type: type,
          payload: data,
        );
      }
    } catch (e) {
      debugPrint('Error sending notification to role $role: $e');
    }
  }

  // Send notification to specific topic
  static Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Client-side FCM implementation would require server-side API
    // For now, just create a local notification
    debugPrint('Topic notification not implemented in client side. Topic: $topic, Title: $title, Body: $body');
  }

  // Subscribe user to topic
  static Future<void> subscribeUserToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe user from topic
  static Future<void> unsubscribeUserFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Send attendance notification to parent when student's attendance status changes
  static Future<void> sendAttendanceNotificationToParent({
    required String studentId,
    required String parentUserId,
    required String subject,
    required String status, // 'present', 'absent', 'leave'
    String? teacherName,
  }) async {
    try {
      String title, body;
      
      switch (status) {
        case 'present':
          title = 'แจ้งเตือนการมาเรียน';
          body = 'นักเรียน ${studentId} เข้าเรียนวิชา ${subject} แล้ว';
          break;
        case 'leave':
          title = 'แจ้งเตือนการลา';
          body = 'นักเรียน ${studentId} ได้ทำการลาเรียนวิชา ${subject}';
          break;
        case 'absent':
          title = 'แจ้งเตือนการขาดเรียน';
          body = 'นักเรียน ${studentId} ขาดเรียนวิชา ${subject}';
          break;
        default:
          title = 'อัปเดตสถานะการมาเรียน';
          body = 'นักเรียน ${studentId} มีการอัปเดตสถานะการมาเรียนวิชา ${subject}';
      }

      await sendNotificationToUser(
        userId: parentUserId,
        title: title,
        body: body,
        data: {
          'type': 'attendance_update',
          'studentId': studentId,
          'subject': subject,
          'status': status,
          'timestamp': Timestamp.now().toDate().toString(),
        },
      );
    } catch (e) {
      debugPrint('Error sending attendance notification: $e');
    }
  }

  // Send attendance notification to student when their attendance is updated
  static Future<void> sendAttendanceNotificationToStudent({
    required String studentId,
    required String subject,
    required String status,
    String? teacherName,
  }) async {
    try {
      String title, body;
      
      switch (status) {
        case 'present':
          title = 'การมาเรียน';
          body = 'คุณมาเรียนวิชา ${subject} แล้ว';
          break;
        case 'leave':
          title = 'การลาเรียน';
          body = 'คุณได้รับอนุญาตให้ลากิจวิชา ${subject}';
          break;
        case 'absent':
          title = 'การขาดเรียน';
          body = 'คุณขาดเรียนวิชา ${subject}';
          break;
        default:
          title = 'อัปเดตสถานะการมาเรียน';
          body = 'มีการอัปเดตสถานะการมาเรียนวิชา ${subject}';
      }

      await sendNotificationToUser(
        userId: studentId,
        title: title,
        body: body,
        data: {
          'type': 'attendance_update',
          'subject': subject,
          'status': status,
          'timestamp': Timestamp.now().toDate().toString(),
        },
      );
    } catch (e) {
      debugPrint('Error sending student attendance notification: $e');
    }
  }

  // Private method to send notification to device
  static Future<void> _sendToDevice(
    String token,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    // For client-side sending, we need to use local notifications
    // since FCM HTTP API requires server-side implementation
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'channel_id', // Channel ID
            'channel_name', // Channel name
            channelDescription: 'Channel description', // Channel description
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      final notificationService = NotificationService();
      await notificationService.localNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: data != null ? data.toString() : null,
      );
    } catch (e) {
      debugPrint('Error sending local notification: $e');
    }
  }
  
  // Method to create notification in Firestore
  static Future<void> createFirestoreNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String senderId = 'system',
    String senderName = 'ระบบ',
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Import the Firestore notification service here
      // Since we can't import circularly, we'll use direct Firestore operations
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Get current user as sender if not specified
      final currentUser = auth.currentUser;
      if (currentUser != null && senderId == 'system') {
        senderId = currentUser.uid;
        DocumentSnapshot userDoc = await firestore.collection('Users').doc(senderId).get();
        senderName = userDoc.get('name') ?? 'ไม่ทราบชื่อ';
      }
      
      String notificationId = firestore.collection('Notifications').doc().id;
      await firestore.collection('Notifications').doc(notificationId).set({
        'id': notificationId,
        'title': title,
        'body': body,
        'type': type,
        'senderId': senderId,
        'senderName': senderName,
        'recipientId': userId,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'payload': payload ?? {},
      });
    } catch (e) {
      debugPrint('Error creating Firestore notification: $e');
    }
  }

  // Update user's FCM token in Firestore
  static Future<void> updateUserToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user token: $e');
    }
  }
  
  // QR Scan related notification functions
  
  /// Handle student arrival at school
  static Future<void> handleStudentSchoolArrival({
    required String studentId,
    required String studentName,
  }) async {
    // TODO: In production, call backend API to send notification to parents
    debugPrint('Student $studentName (ID: $studentId) arrived at school. Should notify parents.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-school-arrival', {
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student class check-in
  static Future<void> handleStudentClassCheckin({
    required String studentId,
    required String studentName,
    required String subjectId,
    required String subjectName,
  }) async {
    // TODO: In production, call backend API to send notification to parents
    debugPrint('Student $studentName (ID: $studentId) checked in to subject $subjectName (ID: $subjectId). Should notify parents.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-class-checkin', {
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'subjectId': subjectId,
    //   'subjectName': subjectName,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student departure from school
  static Future<void> handleStudentSchoolDeparture({
    required String studentId,
    required String studentName,
  }) async {
    // TODO: In production, call backend API to send notification to parents
    debugPrint('Student $studentName (ID: $studentId) departed from school. Should notify parents.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-school-departure', {
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  // Bus tracking related notification functions
  
  /// Handle bus departure (school bound)
  static Future<void> handleBusDepartureToSchool({
    required String busId,
    required String driverId,
    required List<String> studentIds, // Students who will be on this bus
  }) async {
    // TODO: In production, call backend API to send notification to parents of all students
    debugPrint('Bus $busId departed heading to school with driver $driverId. Should notify parents of ${studentIds.length} students.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/bus-departure-school', {
    //   'busId': busId,
    //   'driverId': driverId,
    //   'studentIds': studentIds,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student pickup by bus
  static Future<void> handleStudentBusPickup({
    required String studentId,
    required String studentName,
    required String busId,
    required String location,
  }) async {
    // TODO: In production, call backend API to send notification to specific student's parent
    debugPrint('Student $studentName (ID: $studentId) was picked up by bus $busId at $location. Should notify parent.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-bus-pickup', {
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'busId': busId,
    //   'location': location,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle bus arrival at school with students
  static Future<void> handleBusArrivalAtSchool({
    required String busId,
    required String driverId,
    required List<String> studentIds,
  }) async {
    // TODO: In production, call backend API to send notification to parents of all students
    debugPrint('Bus $busId arrived at school with driver $driverId. Should notify parents of ${studentIds.length} students.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/bus-arrival-school', {
    //   'busId': busId,
    //   'driverId': driverId,
    //   'studentIds': studentIds,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle bus departure (home bound)
  static Future<void> handleBusDepartureToHome({
    required String busId,
    required String driverId,
    required List<String> studentIds, // Students who were on the bus to school
  }) async {
    // TODO: In production, call backend API to send notification to parents of all students
    debugPrint('Bus $busId departed heading home with driver $driverId. Should notify parents of ${studentIds.length} students.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/bus-departure-home', {
    //   'busId': busId,
    //   'driverId': driverId,
    //   'studentIds': studentIds,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student pickup from school by bus
  static Future<void> handleStudentSchoolBusPickup({
    required String busId,
    required String driverId,
    required List<String> studentIds,
  }) async {
    // TODO: In production, call backend API to send notification to parents of all students
    debugPrint('Bus $busId picked up students from school. Should notify parents of ${studentIds.length} students.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-pickup-from-school', {
    //   'busId': busId,
    //   'driverId': driverId,
    //   'studentIds': studentIds,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student drop-off at home by bus
  static Future<void> handleStudentBusDropoffAtHome({
    required String studentId,
    required String studentName,
    required String busId,
    required String location,
  }) async {
    // TODO: In production, call backend API to send notification to specific student's parent
    debugPrint('Student $studentName (ID: $studentId) was dropped off at home by bus $busId. Should notify parent.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/student-bus-dropoff-home', {
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'busId': busId,
    //   'location': location,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Private method to call backend API (placeholder)
  /// This method would be implemented in a real backend service
  static Future<void> _callBackendAPI(String endpoint, Map<String, dynamic> data) async {
    // This is where the actual HTTP call to your backend would happen
    // The backend would then use FCM server SDK to send notifications
    debugPrint('Would call backend API: $endpoint with data: $data');
  }
  
  // Homework related notification functions
  
  /// Handle teacher assigning homework
  static Future<void> handleHomeworkAssigned({
    required String assignmentId,
    required String teacherId,
    required String teacherName,
    required String subjectId,
    required String subjectName,
    required String assignmentTitle,
    required String assignmentDescription,
    required DateTime dueDate,
    required List<String> assignedStudentIds,
  }) async {
    // TODO: In production, call backend API to send notification to students and parents
    debugPrint('Homework "$assignmentTitle" assigned by $teacherName in subject $subjectName. Should notify ${assignedStudentIds.length} students and their parents.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/homework-assigned', {
    //   'assignmentId': assignmentId,
    //   'teacherId': teacherId,
    //   'teacherName': teacherName,
    //   'subjectId': subjectId,
    //   'subjectName': subjectName,
    //   'assignmentTitle': assignmentTitle,
    //   'assignmentDescription': assignmentDescription,
    //   'dueDate': dueDate.toIso8601String(),
    //   'assignedStudentIds': assignedStudentIds,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle student submitting homework
  static Future<void> handleHomeworkSubmitted({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String teacherId,
    required String assignmentTitle,
  }) async {
    // TODO: In production, call backend API to send notification to teacher
    debugPrint('Student $studentName submitted homework "$assignmentTitle". Should notify teacher.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/homework-submitted', {
    //   'assignmentId': assignmentId,
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'teacherId': teacherId,
    //   'assignmentTitle': assignmentTitle,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle assignment deadline reminder
  static Future<void> handleDeadlineReminder({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String assignmentTitle,
    required String subjectName,
    required DateTime dueDate,
    required int daysRemaining,
  }) async {
    // TODO: In production, call backend API to send reminder notification to student
    debugPrint('Reminder: Assignment "$assignmentTitle" in subject $subjectName is due in $daysRemaining days. Should notify student $studentName.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/deadline-reminder', {
    //   'assignmentId': assignmentId,
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'assignmentTitle': assignmentTitle,
    //   'subjectName': subjectName,
    //   'dueDate': dueDate.toIso8601String(),
    //   'daysRemaining': daysRemaining,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Handle assignment overdue notification
  static Future<void> handleAssignmentOverdue({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String assignmentTitle,
    required String subjectName,
    required DateTime dueDate,
  }) async {
    // TODO: In production, call backend API to send overdue notification to student and parent
    debugPrint('Assignment "$assignmentTitle" in subject $subjectName is overdue. Should notify student $studentName and parent.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/assignment-overdue', {
    //   'assignmentId': assignmentId,
    //   'studentId': studentId,
    //   'studentName': studentName,
    //   'assignmentTitle': assignmentTitle,
    //   'subjectName': subjectName,
    //   'dueDate': dueDate.toIso8601String(),
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  // Announcement notification functions
  
  /// Handle public announcement to all users (students, parents, drivers)
  static Future<void> handlePublicAnnouncement({
    required String announcementId,
    required String senderId,
    required String senderName,
    required String title,
    required String content,
    required List<String> targetRoles, // e.g., ['student', 'parent', 'driver']
  }) async {
    // TODO: In production, call backend API to send announcement notification to all targeted users
    debugPrint('Public announcement "$title" from $senderName. Should notify users with roles: ${targetRoles.join(', ')}.');
    
    // Placeholder for future backend call
    // await _callBackendAPI('/notifications/public-announcement', {
    //   'announcementId': announcementId,
    //   'senderId': senderId,
    //   'senderName': senderName,
    //   'title': title,
    //   'content': content,
    //   'targetRoles': targetRoles,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Send announcement to specific role (students, parents, drivers)
  static Future<void> sendAnnouncementToRole({
    required String role,
    required String title,
    required String content,
    String? senderName,
  }) async {
    try {
      // Create notification data payload
      Map<String, dynamic> notificationData = {
        'type': 'public_announcement',
        'senderName': senderName ?? 'System',
        'title': title,
        'content': content,
        'timestamp': Timestamp.now().toDate().toString(),
        'isAnnouncement': true,
      };

      // Send notification to all users with the specified role
      await sendNotificationToRole(
        role: role,
        title: title,
        body: content,
        data: notificationData,
      );
      
      debugPrint('Announcement sent to role: $role');
    } catch (e) {
      debugPrint('Error sending announcement to role $role: $e');
    }
  }
  
  // Enhanced method to create notification for all users with a specific role
  static Future<void> createNotificationForRole({
    required String role,
    required String title,
    required String body,
    required String type,
    String senderId = 'system',
    String senderName = 'ระบบ',
    Map<String, dynamic>? payload,
  }) async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: role)
          .get();

      for (var userDoc in usersSnapshot.docs) {
        await createFirestoreNotification(
          userId: userDoc.id,
          title: title,
          body: body,
          type: type,
          senderId: senderId,
          senderName: senderName,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Error creating notification for role $role: $e');
    }
  }
}