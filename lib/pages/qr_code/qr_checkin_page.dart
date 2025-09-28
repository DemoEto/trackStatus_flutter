import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../utils/notification_helper.dart';

class QrCheckinPage extends StatefulWidget {
  final bool fromQrScan;
  final String subId;
  final String date;
  const QrCheckinPage({
    super.key,
    this.fromQrScan = false,
    required this.subId,
    required this.date,
  });

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  String? qrData;
  final String? _status = "present"; // ค่าเริ่มต้น = มา
  Map<String, dynamic>? studentData; // เก็บข้อมูลนักเรียนจาก Firestore
  List<Map<String, dynamic>> scannedStudents = []; // เก็บนักเรียนที่สแกนเข้ามา

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final userService = UserService();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.fromQrScan == true) {
      userService.streamUser("$uid");
      addCurrentUserToList();
    }
    // print('🤣 ${today}');
    _loadSubjects();
  }

  // ✅ บันทึกตอนครูกดยืนยัน
  Future<void> submitAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final batch = FirebaseFirestore.instance.batch();

    for (var student in scannedStudents) {
      final ref = FirebaseFirestore.instance
          .collection('Attendance')
          .doc('${student['uid']}_$today');

      batch.set(ref, {
        'studentId': student['id'],
        'name': student['name'],
        'status': student['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Send notification to parent about attendance status
      await _sendAttendanceNotificationToParent(
        studentId: student['id'],
        studentName: student['name'],
        status: student['status'],
        subject: selectedSubject ?? 'General',
      );
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกการมาเรียนเรียบร้อย")));
    }

    setState(() {
      scannedStudents.clear(); // เคลียร์ list หลังบันทึก
    });
  }

  onQrScanned(String scannedData) async {
    // สมมุติว่า QR เก็บ stdId ไว้
    final attendanceService = AttendanceService();
    await attendanceService.savePendingAttendance(
      stdId: scannedData,
      status: "present",
      subId: "", // หรือค่า subId ที่คุณมี
      teacherId: "", // หรือค่า teacherId ที่คุณมี
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกการสแกนเรียบร้อย")));
    }
  }

  // ✅ บันทึกตอนครูกดยืนยัน
  Future<void> pendingAttendance() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final batch = FirebaseFirestore.instance.batch();

    for (var student in scannedStudents) {
      final ref = FirebaseFirestore.instance
          .collection('Attendance')
          .doc('${student['uid']}_$today');

      batch.set(ref, {
        'studentId': student['id'],
        'name': student['name'],
        'status': student['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกการมาเรียนเรียบร้อย")));
    }

    setState(() {
      scannedStudents.clear(); // เคลียร์ list หลังบันทึก
    });
  }

  //-- fecth data subjects from firestore
  List<String> subjectList = [];
  String? selectedSubject;

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Subjects')
        .get();
    setState(() {
      subjectList = snapshot.docs
          .map(
            (doc) =>
                doc.data()['name']?.toString() ?? "",
          )
          .toList();
    });
  }

  Widget _formCreateQR() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: SizedBox(
        width: 480,
        child: Column(
        children: [
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('Subjects').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("ไม่มีวิชาในระบบ");
              }
              // สร้าง List ของ Map สำหรับใช้ใน Dropdown
              List<Map<String, String>> subjects = snapshot.data!.docs.map((
                doc,
              ) {
                final data = doc.data() as Map<String, dynamic>;
                final subId = data['id']?.toString() ?? "";
                final subName = data['name']?.toString() ?? "ไม่ระบุชื่อวิชา";

                return {"id": subId, "name": subName};
              }).toList();

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "เลือกวิชา",
                  border: OutlineInputBorder(),
                ),
                value: selectedSubject,
                items: subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject['id'], // ✅ value เป็น subId
                        child: Text(
                          "${subject['id']!} : ${subject['name']!}",
                        ), // แสดงชื่อวิชา
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubject = value;
                  });
                },
                validator: (value) => value == null ? "กรุณาเลือกวิชา" : null,
              );
            },
          ),
          SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () async {
              if (selectedSubject != null) {
                final user = FirebaseAuth.instance.currentUser;
                final teacherId = user?.uid ?? "";
                setState(() {
                  qrData =
                      "AppRoutes.qrCheckinScan/${selectedSubject}/${today}/${teacherId}";
                });
                print("❤️ $qrData");
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกวิชา")));
                }
              }
            },
            child: const Text("สร้าง QR Code"),
          ),
        ],
      ),
      )
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

    // ตรวจว่าคนนี้ยังไม่อยู่ใน list
    final exists = scannedStudents.any((s) => s['uid'] == user.uid);
    if (exists) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      scannedStudents.add({
        'uid': user.uid,
        'id': data['id'],
        'name': data['name'],
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
      // Find parent of this student and send notification
      QuerySnapshot parentSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'parent')
          .get();
          
      for (var parentDoc in parentSnapshot.docs) {
        List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
        if (children != null && children.contains(studentId)) {
          await NotificationHelper.sendAttendanceNotificationToParent(
            studentId: studentId,
            parentUserId: parentDoc.id,
            subject: subject,
            status: status,
          );
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
    return Scaffold(
      appBar: AppBar(title: const Text("QR & Check-In")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<String?>(
              stream: userService.streamUserRole(), // ดึง role จาก service
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // ระหว่างโหลดไม่ต้องโชว์อะไร
                }

                final role = snapshot.data;

                if (role == "teacher" || role == "admin")
                  return _formCreateQR();

                return const SizedBox.shrink();
              },
            ),
            // TODO: show qr
            if (qrData != null) _qrGenerator(qrData!),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: SizedBox.shrink()),
                  Expanded(child: Center(child: Text("มา"))),
                  Expanded(child: Center(child: Text("ลา"))),
                  Expanded(child: Center(child: Text("ขาด"))),
                ],
              ),
            ),
            Divider(thickness: 1, color: Colors.grey.shade400),

            // Student Row
            ...scannedStudents.map((s) => _buildStudentRow(s)).toList(),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<String?>(
        stream: userService.streamUserRole(), // ดึง role จาก service
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); // ระหว่างโหลดไม่ต้องโชว์อะไร
          }

          final role = snapshot.data;

          if (role == "teacher") {
            return FloatingActionButton.extended(
              onPressed: submitAttendance,
              label: const Text("ยืนยัน"),
              icon: const Icon(Icons.check),
            );
          }
          return const SizedBox.shrink(); // ถ้าไม่ใช่ครู -> ไม่แสดงปุ่ม
        },
      ), // ไม่แสดงปุ่ม
    );
  }
}
