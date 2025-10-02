import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

import '../../routes/app_route.dart';
import '../../services/attendance_service.dart';
import '../../services/notification_service.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false; // กันซ้ำ
  
  final AttendanceService _attendanceService = AttendanceService();
  final NotificationService _notificationService = NotificationService();

  // Handle class check-in notification
  Future<void> _handleClassCheckin(String? currentUserId, String subjectId) async {
    if (currentUserId == null) return;

    try {
      // Get student info from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
      if (userDoc.exists) {
        String studentName = userDoc.get('name') ?? currentUserId;
        
        // Get subject info
        DocumentSnapshot subjectDoc = await FirebaseFirestore.instance.collection('Subjects').doc(subjectId).get();
        String subjectName = subjectDoc.exists ? subjectDoc.get('name') ?? subjectId : subjectId;
        
        // Use NotificationService to send notifications to the student and their parents
        // Send notification to student
        String? deviceToken = userDoc.get('fcmToken') as String?;

        // Create a Firestore notification for the student
        String notificationId = await _notificationService.createFirestoreNotification(
          title: 'เข้าเรียนวิชา $subjectName',
          body: 'คุณได้เข้าเรียนวิชา $subjectName เรียบร้อยแล้ว',
          type: 'class_checkin',
          senderId: 'system',
          senderName: 'ระบบ',
          recipientId: currentUserId,
          payload: {
            'studentId': currentUserId,
            'studentName': studentName,
            'subjectId': subjectId,
            'subjectName': subjectName,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );

        // Send push notification to the student if device token is available
        if (deviceToken != null) {
          await _notificationService.sendPushNotification(
            deviceToken: deviceToken,
            title: 'เข้าเรียนวิชา $subjectName',
            body: 'คุณได้เข้าเรียนวิชา $subjectName เรียบร้อยแล้ว',
            data: {
              'type': 'class_checkin',
              'notificationId': notificationId,
              'subjectId': subjectId,
              'subjectName': subjectName,
            },
          );
        }

        // Send notification to parents of this student
        QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('role', isEqualTo: 'parent')
            .get();
            
        for (var parentDoc in parentSnapshot.docs) {
          List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
          if (children != null && children.contains(currentUserId)) {
            String? parentDeviceToken = parentDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the parent
            String parentNotificationId = await _notificationService.createFirestoreNotification(
              title: 'นักเรียนเข้าเรียนวิชา $subjectName',
              body: 'ลูกของคุณ $studentName ได้เข้าเรียนวิชา $subjectName เรียบร้อยแล้ว',
              type: 'class_checkin',
              senderId: 'system',
              senderName: 'ระบบ',
              recipientId: parentDoc.id,
              payload: {
                'studentId': currentUserId,
                'studentName': studentName,
                'subjectId': subjectId,
                'subjectName': subjectName,
                'timestamp': Timestamp.now().toDate().toString(),
              },
            );

            // Send push notification to the parent if device token is available
            if (parentDeviceToken != null) {
              await _notificationService.sendPushNotification(
                deviceToken: parentDeviceToken,
                title: 'นักเรียนเข้าเรียนวิชา $subjectName',
                body: 'ลูกของคุณ $studentName ได้เข้าเรียนวิชา $subjectName เรียบร้อยแล้ว',
                data: {
                  'type': 'class_checkin',
                  'notificationId': parentNotificationId,
                  'studentId': currentUserId,
                  'subjectName': subjectName,
                },
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling class checkin: $e');
    }
  }

  // Handle school arrival notification
  Future<void> _handleSchoolArrival(String studentId) async {
    try {
      // Get student name from the database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(studentId).get();
      String studentName = userDoc.exists ? userDoc.get('name') ?? studentId : studentId;
      
      // Use NotificationService to send notifications to the student and their parents
      // Send notification to student
      String? deviceToken = userDoc.get('fcmToken') as String?;

      // Create a Firestore notification for the student
      String notificationId = await _notificationService.createFirestoreNotification(
        title: 'ถึงโรงเรียนแล้ว',
        body: 'คุณมาถึงโรงเรียนแล้ว',
        type: 'school_arrival',
        senderId: 'system',
        senderName: 'ระบบ',
        recipientId: studentId,
        payload: {
          'studentId': studentId,
          'studentName': studentName,
          'timestamp': Timestamp.now().toDate().toString(),
        },
      );

      // Send push notification to the student if device token is available
      if (deviceToken != null) {
        await _notificationService.sendPushNotification(
          deviceToken: deviceToken,
          title: 'ถึงโรงเรียนแล้ว',
          body: 'คุณมาถึงโรงเรียนแล้ว',
          data: {
            'type': 'school_arrival',
            'notificationId': notificationId,
            'studentId': studentId,
          },
        );
      }

      // Send notification to parents of this student
      QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'parent')
          .get();
          
      for (var parentDoc in parentSnapshot.docs) {
        List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
        if (children != null && children.contains(studentId)) {
          String? parentDeviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String parentNotificationId = await _notificationService.createFirestoreNotification(
            title: 'นักเรียนมาถึงโรงเรียน',
            body: 'ลูกของคุณ $studentName ได้มาถึงโรงเรียนแล้ว',
            type: 'school_arrival',
            senderId: 'system',
            senderName: 'ระบบ',
            recipientId: parentDoc.id,
            payload: {
              'studentId': studentId,
              'studentName': studentName,
              'timestamp': Timestamp.now().toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (parentDeviceToken != null) {
            await _notificationService.sendPushNotification(
              deviceToken: parentDeviceToken,
              title: 'นักเรียนมาถึงโรงเรียน',
              body: 'ลูกของคุณ $studentName ได้มาถึงโรงเรียนแล้ว',
              data: {
                'type': 'school_arrival',
                'notificationId': parentNotificationId,
                'studentId': studentId,
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling school arrival: $e');
    }
  }

  // Handle school departure notification
  Future<void> _handleSchoolDeparture(String studentId) async {
    try {
      // Get student name from the database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(studentId).get();
      String studentName = userDoc.exists ? userDoc.get('name') ?? studentId : studentId;
      
      // Use NotificationService to send notifications to the student and their parents
      // Send notification to student
      String? deviceToken = userDoc.get('fcmToken') as String?;

      // Create a Firestore notification for the student
      String notificationId = await _notificationService.createFirestoreNotification(
        title: 'ออกจากโรงเรียนแล้ว',
        body: 'คุณออกจากโรงเรียนแล้ว',
        type: 'school_departure',
        senderId: 'system',
        senderName: 'ระบบ',
        recipientId: studentId,
        payload: {
          'studentId': studentId,
          'studentName': studentName,
          'timestamp': Timestamp.now().toDate().toString(),
        },
      );

      // Send push notification to the student if device token is available
      if (deviceToken != null) {
        await _notificationService.sendPushNotification(
          deviceToken: deviceToken,
          title: 'ออกจากโรงเรียนแล้ว',
          body: 'คุณออกจากโรงเรียนแล้ว',
          data: {
            'type': 'school_departure',
            'notificationId': notificationId,
            'studentId': studentId,
          },
        );
      }

      // Send notification to parents of this student
      QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'parent')
          .get();
          
      for (var parentDoc in parentSnapshot.docs) {
        List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
        if (children != null && children.contains(studentId)) {
          String? parentDeviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String parentNotificationId = await _notificationService.createFirestoreNotification(
            title: 'นักเรียนออกจากโรงเรียน',
            body: 'ลูกของคุณ $studentName ได้ออกจากโรงเรียนแล้ว',
            type: 'school_departure',
            senderId: 'system',
            senderName: 'ระบบ',
            recipientId: parentDoc.id,
            payload: {
              'studentId': studentId,
              'studentName': studentName,
              'timestamp': Timestamp.now().toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (parentDeviceToken != null) {
            await _notificationService.sendPushNotification(
              deviceToken: parentDeviceToken,
              title: 'นักเรียนออกจากโรงเรียน',
              body: 'ลูกของคุณ $studentName ได้ออกจากโรงเรียนแล้ว',
              data: {
                'type': 'school_departure',
                'notificationId': parentNotificationId,
                'studentId': studentId,
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling school departure: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("สแกน QR"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Try to pop first, if that doesn't work, go home
            bool? result = await Navigator.of(context).maybePop();
            if (result != true) {
              // If maybePop didn't work, navigate to home
              context.go('/');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_scanned) return; // กันซ้ำ
              _scanned = true;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  // หยุดกล้องทันที
                  _controller.stop();
                  
                  debugPrint('👽${code}');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(code)),
                    );
                  }
                  // Determine the type of QR code and trigger appropriate notification
                  final parts = code.split("/");
                  final qrType = parts[0];
                  
                  if (qrType == "AppRoutes.qrCheckin") {
                    // Handle class check-in
                    if (parts.length >= 3) {
                      final subjectId = parts[1];
                      final date = parts[2];
                      
                      // Get current user as the student and fetch data
                      _handleClassCheckin(FirebaseAuth.instance.currentUser?.uid, subjectId);
                    }
                    
                    // ไปหน้า /qrCheckin แต่ตรวจสอบว่ามี path parameters ครบ
                    if (parts.length >= 4) {
                      // Assuming format is: AppRoutes.qrCheckin/subjectId/date/teacherId/allowLateScans
                      final subjectId = parts[1];
                      final date = parts[2];
                      final teacherId = parts[3];
                      bool allowLateScans = false;
                      
                      if (parts.length >= 5) {
                        allowLateScans = parts[4].toLowerCase() == 'true';
                      }
                      
                      // Save pending attendance with scan time
                      String? studentId = FirebaseAuth.instance.currentUser?.uid;
                      if (studentId != null) {
                        try {
                          await _attendanceService.savePendingAttendance(
                            stdId: studentId,
                            subId: subjectId,
                            teacherId: teacherId,
                            scanTime: DateTime.now(), // Pass scan time
                          );
                        } catch (e) {
                          debugPrint('Error saving pending attendance: $e');
                        }
                      }
                      
                      context.push('/qrCheckinScan/$subjectId/$date/$teacherId/$allowLateScans');
                    } else {
                      // Fallback ถ้าไม่มีข้อมูลครบ
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ข้อมูล QR ไม่ครบถ้วน')),
                        );
                      }
                      context.go('/'); // กลับไปหน้าหลัก
                    }
                  } 
                  else if (qrType == "school_arrival") {
                    // Handle school arrival QR scan - in this case studentId is passed in the QR
                    if (parts.length >= 2) {
                      final studentId = parts[1];
                      _handleSchoolArrival(studentId);
                    }
                  }
                  else if (qrType == "school_departure") {
                    // Handle school departure QR scan - in this case studentId is passed in the QR
                    if (parts.length >= 2) {
                      final studentId = parts[1];
                      _handleSchoolDeparture(studentId);
                    }
                  }
                  else {
                    // ถ้าไม่เจอ path ให้แจ้งเตือนและไป home
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ไม่พบเส้นทาง ไปหน้าแรกแทน')),
                      );
                    }
                    if (mounted) {
                      // Make sure we're using the correct route name
                      context.go('/'); // Navigate to root which redirects to appropriate page
                    }
                  }
                  
                  // Reset the scan flag after a delay to allow new scans
                  await Future.delayed(const Duration(seconds: 2));
                  _scanned = false;
                }
              }
            },
          ),
          // Scanner overlay with instruction
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
              child: const Center(
                child: Text(
                  'วาง QR Code ไว้ในกรอบ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Scanner frame in the center
          const Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: ColoredBox(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(width: 3, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
