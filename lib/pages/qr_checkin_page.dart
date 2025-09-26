import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/user_service.dart';
import '../services/addPendingAttendance.dart';
import '../models/user_model.dart';

class QrCheckinPage extends StatefulWidget {
  final bool fromQrScan;
  const QrCheckinPage({super.key, this.fromQrScan = false});

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  String? qrData = 'AppRoutes.qrCheckin';
  String? _status = "present"; // ค่าเริ่มต้น = มา
  Map<String, dynamic>? studentData; // เก็บข้อมูลนักเรียนจาก Firestore
  List<Map<String, dynamic>> scannedStudents = []; // เก็บนักเรียนที่สแกนเข้ามา

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final userService = UserService();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.fromQrScan == true) {
      userService.streamUser("$uid");
      addCurrentUserToList();
    }
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
        'studentId': student['stdId'],
        'name': student['name'],
        'status': student['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึกการมาเรียนเรียบร้อย")),
    );

    setState(() {
      scannedStudents.clear(); // เคลียร์ list หลังบันทึก
    });
  }

  //-- QR Generator
  Widget _qrGenerator() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: PrettyQrView.data(
        data: qrData!,
        errorCorrectLevel: QrErrorCorrectLevel.H,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(),
          image: PrettyQrDecorationImage(
            image: AssetImage('assets/images/login2.png'),
            position: PrettyQrDecorationImagePosition.embedded,
            padding: EdgeInsets.all(25),
          ),
          quietZone: PrettyQrQuietZone.modules(6),
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
        'stdId': data['stdId'],
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
                Text(student['stdId']),
                Text(student['name']),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR & Check-In")),
      body: Column(
        children: [
          _qrGenerator(),
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
