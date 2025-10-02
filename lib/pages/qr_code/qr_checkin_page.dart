import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/notification_service.dart';

class QrCheckinPage extends StatefulWidget {
  final bool fromQrScan;
  final String subId;
  final String date;
  final String teacherId;
  final bool allowLateScans; // เพิ่มตัวแปรสำหรับอนุญาตการสแกนซ้ำของนักเรียนสาย
  const QrCheckinPage({
    super.key,
    this.fromQrScan = false,
    required this.subId,
    required this.date,
    this.teacherId = '',
    this.allowLateScans = false, // Default to false
  });

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  String? qrData;
  final String? _status = "present"; // ค่าเริ่มต้น = มา
  bool _allowLateScans = false; // ตัวแปรสำหรับอนุญาตการสแกนซ้ำสำหรับนักเรียนสาย
  Map<String, dynamic>? studentData; // เก็บข้อมูลนักเรียนจาก Firestore
  List<Map<String, dynamic>> scannedStudents = []; // เก็บนักเรียนที่สแกนเข้ามา

  final _auth = FirebaseAuth.instance;
  // final _firestore = FirebaseFirestore.instance; // Removed: Use service only
  final userService = UserService();
  final attendanceService = AttendanceService();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Stepper variables
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.fromQrScan == true) {
      userService.streamUser("$uid");
      // The addCurrentUserToList function now checks role internally
      addCurrentUserToList();
    }
    _loadSubjects();
  }

  // ✅ บันทึกตอนครูกดยืนยัน
  Future<void> submitAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var student in scannedStudents) {
      // Use AttendanceService to save attendance
      await attendanceService.addAttendance(
        studentId: student['id'],
        name: student['name'],
        status: student['status'],
        timestamp: DateTime.now(),
        subjectId: selectedSubject ?? 'General',
        teacherId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      
      // Send notification to parent about attendance status
      await _sendAttendanceNotificationToParent(
        studentId: student['id'],
        studentName: student['name'],
        status: student['status'],
        subject: selectedSubject ?? 'General',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกการมาเรียนเรียบร้อย")));
      
      // Reset after successful submission
      setState(() {
        _currentStep = 0;
        scannedStudents.clear();
        selectedSubject = null;
        qrData = null;
      });
    }
  }

  Future<void> onQrScanned(String scannedData) async {
    // Check if current user is authorized to perform attendance using UserService
    bool isAuthorized = await userService.isAuthorizedForAttendance();
    
    if (!isAuthorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("คุณไม่มีสิทธิ์ในการสแกนเช็กอิน"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Call savePendingAttendance without status parameter (status will be determined by time)
      await attendanceService.savePendingAttendance(
        stdId: scannedData,
        subId: selectedSubject ?? "", // Use the selected subject
        teacherId: FirebaseAuth.instance.currentUser?.uid ?? "", // Use current teacher ID
        scanTime: DateTime.now(), // Pass scan time
      );

      // Add the student to the scanned list if not already there
      Map<String, dynamic>? studentData = await userService.getUserById(scannedData);
          
      if (studentData != null) {
        // Check if student is already in the list
        bool studentExists = scannedStudents.any((student) => student['uid'] == scannedData);
        
        if (!studentExists) {
          // Get status from PendingAttendance collection - this may still require direct access
          // For now, we'll use default status
          String status = 'present'; // Default
        
          setState(() {
            scannedStudents.add({
              'uid': scannedData,
              'id': studentData['id'] ?? scannedData,
              'name': studentData['name'] ?? 'ไม่ทราบชื่อ',
              'status': status, // Use status determined by time
            });
          });
          
          if (mounted) {
            String statusText = status == 'present' ? 'มาเรียน' : (status == 'late' ? 'มาเรียนสาย' : 'ขาดเรียน');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("เพิ่มนักเรียน ${studentData['name'] ?? scannedData} - $statusText เรียบร้อย"),
                backgroundColor: status == 'present' ? Colors.green : (status == 'late' ? Colors.orange : Colors.red),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("นักเรียนคนนี้สแกนไปแล้ว"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("ไม่พบข้อมูลนักเรียน"),
                backgroundColor: Colors.red,
              ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ บันทึกตอนครูกดยืนยัน
  Future<void> pendingAttendance() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var student in scannedStudents) {
      // Use AttendanceService to save attendance
      await attendanceService.addAttendance(
        studentId: student['id'],
        name: student['name'],
        status: student['status'],
        timestamp: DateTime.now(),
        subjectId: selectedSubject ?? 'General',
        teacherId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกการมาเรียนเรียบร้อย")));
    }

    setState(() {
      scannedStudents.clear(); // เคลียร์ list หลังบันทึก
    });
  }

  //-- fecth data subjects from service
  List<String> subjectList = [];
  String? selectedSubject;

  Future<void> _loadSubjects() async {
    // This will be updated to use a new service method
    // For now, we'll leave this for the service to implement
    // Future: Add a subject service that handles subject-related operations
  }

  // First step: Select Subject
  Widget _step1SelectSubject() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "เลือกวิชา",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<String?>(
            stream: userService.streamUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final role = snapshot.data;
              
              if (role != "teacher" && role != "admin") {
                return const Center(
                  child: Text("คุณไม่มีสิทธิ์ในการสร้าง QR สำหรับเช็กอิน"),
                );
              }
              
              // This section would use a new subject service
              // For now, placeholder - subject service needs to be created
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "เลือกวิชา",
                  border: OutlineInputBorder(),
                ),
                value: null,
                items: [], // Will be populated by a service
                onChanged: (value) {
                  // Handle selection
                },
                validator: (value) => value == null ? "กรุณาเลือกวิชา" : null,
              );
            },
          ),
          const SizedBox(height: 20),
          // Add option for re-opening QR for late students
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ตัวเลือกพิเศษ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _allowLateScans,
                      onChanged: (value) {
                        setState(() {
                          _allowLateScans = value ?? false;
                        });
                      },
                    ),
                    const Text("อนุญาตให้นักเรียนที่มาสายสแกน QR ซ้ำได้"),
                  ],
                ),
                if (_allowLateScans)
                  const Text(
                    "ระบบจะเปิด QR ให้นักเรียนที่มาสายสามารถสแกนอีกครั้งได้",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //-- QR Generator (Step 2)
  Widget _step2ShowQR() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "แสดง QR Code",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (qrData != null)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: PrettyQrView.data(
                  data: qrData!,
                  errorCorrectLevel: QrErrorCorrectLevel.H,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(),
                    image: PrettyQrDecorationImage(
                      image: AssetImage('assets/images/login2.png'),
                      position: PrettyQrDecorationImagePosition.embedded,
                      padding: EdgeInsets.all(12),
                    ),
                    quietZone: PrettyQrQuietZone.modules(3),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            "ให้นักเรียนสแกน QR Code นี้เพื่อเช็กอิน",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Summary
  Widget _step3Summary() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "สรุปรายชื่อนักเรียน",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text("ชื่อ-นามสกุล", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Center(child: Text("มา", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("ลากิจ", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("ขาด", style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const Divider(thickness: 1, color: Colors.grey),
          
          // Student Rows
          if (scannedStudents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("ยังไม่มีนักเรียนสแกนเข้ามา"),
              ),
            ),
          ...scannedStudents.map((s) => _buildStudentRow(s)).toList(),
        ],
      ),
    );
  }

  //-- QR Generator
  Widget _qrGenerator(String qrData) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 480, // ✅ กำหนดขนาดเล็กลง
        height: 480,
        child: PrettyQrView.data(
          data: qrData,
          errorCorrectLevel: QrErrorCorrectLevel.H,
          decoration: const PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(),
            image: PrettyQrDecorationImage(
              image: AssetImage('assets/images/login2.png'),
              position: PrettyQrDecorationImagePosition.embedded,
              padding: EdgeInsets.all(12), // ปรับ padding ให้เล็กลง
            ),
            quietZone: PrettyQrQuietZone.modules(3), // ลด quietZone ลง
          ),
        ),
      ),
    );
  }


  Future<void> addCurrentUserToList() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Use UserService to get user data
    Map<String, dynamic>? userData = await userService.getUserById(user.uid);
    if (userData == null) return;

    String? userRole = userData['role']?.toString();

    // Don't add teachers or admins to the student attendance list
    if (userRole == 'teacher' || userRole == 'admin') {
      return;
    }

    // ตรวจว่าคนนี้ยังไม่อยู่ใน list
    final exists = scannedStudents.any((s) => s['uid'] == user.uid);
    if (exists) return;

    setState(() {
      scannedStudents.add({
        'uid': user.uid,
        'id': userData['id'],
        'name': userData['name'],
        'status': 'present', // ค่า default
      });
    });
  }

  Widget _buildStudentRow(Map<String, dynamic> student) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['id'] ?? 'n/a',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  student['name'] ?? 'n/a',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: 'present',
              groupValue: student['status'],
              onChanged: (val) {
                setState(() {
                  student['status'] = val!;
                });
              },
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: 'leave',
              groupValue: student['status'],
              onChanged: (val) {
                setState(() {
                  student['status'] = val!;
                });
              },
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: 'absent',
              groupValue: student['status'],
              onChanged: (val) {
                setState(() {
                  student['status'] = val!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Send notification to parent about student attendance
  Future<void> _sendAttendanceNotificationToParent({
    required String studentId,
    required String studentName,
    required String status,
    required String subject,
  }) async {
    try {
      final notificationService = NotificationService();
      // Find parent of this student using UserService
      QuerySnapshot? parentSnapshot;
      await for (var snapshot in userService.getParentsByChildId(studentId)) {
        parentSnapshot = snapshot;
        break; // Get the first snapshot
      }
      
      if (parentSnapshot != null) {
        for (var parentDoc in parentSnapshot.docs) {
          String title, body;
          
          switch (status) {
            case 'present':
              title = 'แจ้งเตือนการมาเรียน';
              body = 'นักเรียน $studentName เข้าเรียนวิชา $subject แล้ว';
              break;
            case 'leave':
              title = 'แจ้งเตือนการลา';
              body = 'นักเรียน $studentName ได้ทำการลาเรียนวิชา $subject';
              break;
            case 'absent':
              title = 'แจ้งเตือนการขาดเรียน';
              body = 'นักเรียน $studentName ขาดเรียนวิชา $subject';
              break;
            default:
              title = 'อัปเดตสถานะการมาเรียน';
              body = 'นักเรียน $studentName มีการอัปเดตสถานะการมาเรียนวิชา $subject';
          }

          // Get parent's device token to send push notification
          String? deviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String notificationId = await notificationService.createFirestoreNotification(
            title: title,
            body: body,
            type: 'attendance_update',
            senderId: FirebaseAuth.instance.currentUser?.uid ?? 'system',
            senderName: 'ระบบ',
            recipientId: parentDoc.id,
            payload: {
              'studentId': studentId,
              'studentName': studentName,
              'subject': subject,
              'status': status,
              'timestamp': Timestamp.now().toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (deviceToken != null) {
            await notificationService.sendPushNotification(
              deviceToken: deviceToken,
              title: title,
              body: body,
              data: {
                'type': 'attendance_update',
                'notificationId': notificationId,
                'studentId': studentId,
                'studentName': studentName,
                'subject': subject,
                'status': status,
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending notification to parent: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text("ไม่พบผู้ใช้");
    
    // Check user role before building the page
    return StreamBuilder<String?>(
      stream: userService.streamUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final role = snapshot.data;
        
        if (role != "teacher" && role != "admin") {
          return Scaffold(
            appBar: AppBar(
              title: const Text("เช็กอินด้วย QR Code"),
              centerTitle: true,
            ),
            body: const Center(
              child: Text(
                "คุณไม่มีสิทธิ์ในการสร้าง QR สำหรับเช็กอิน",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text("เช็กอินด้วย QR Code"),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stepper header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStepIndicator(0, "เลือกวิชา"),
                      _buildStepConnector(0, 1),
                      _buildStepIndicator(1, "แสดง QR"),
                      _buildStepConnector(1, 2),
                      _buildStepIndicator(2, "สรุป"),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Content based on current step
                switch (_currentStep) {
                  0 => _step1SelectSubject(),
                  1 => _step2ShowQR(),
                  2 => _step3Summary(),
                  _ => _step1SelectSubject(), // fallback
                },
              ],
            ),
          ),
          // Move navigation buttons to bottomNavigationBar
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
    );
  }
  
  // Build bottom navigation with step navigation buttons
  Widget _buildBottomNavigation() {
    // Back button - only show when not on first step
    Widget backButton = _currentStep > 0
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("ย้อนกลับ"),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Next/Submit button - text changes based on step
    Widget nextButton = _currentStep < 2
        ? Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validation for step 0 (subject selection)
                  if (_currentStep == 0 && selectedSubject == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("กรุณาเลือกวิชา")),
                    );
                    return;
                  }

                  setState(() {
                    _currentStep++;

                    // Generate QR code when moving to step 2
                    if (_currentStep == 1) {
                      final user = FirebaseAuth.instance.currentUser;
                      final teacherId = user?.uid ?? "";
                      qrData = "AppRoutes.qrCheckinScan/${selectedSubject}/${today}/${teacherId}/${_allowLateScans}";
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("ถัดไป"),
              ),
            ),
          )
        : Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: scannedStudents.isEmpty ? null : submitAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("ยืนยัน"),
              ),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 197, 211, 232),
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: _currentStep == 0
          // If on first step (no back button), show next button as full width
          ? nextButton
          // If on other steps (with back and next/submit buttons), show both buttons split
          : Row(
              children: [
                backButton,
                nextButton,
              ],
            ),
    );
  }
  
  Widget _buildStepIndicator(int index, String title) {
    bool isActive = index == _currentStep;
    bool isCompleted = index < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary : isCompleted ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).colorScheme.primary : isCompleted ? Colors.green : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepConnector(int fromStep, int toStep) {
    bool isCompleted = toStep <= _currentStep;
    
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
    );
  }
}
