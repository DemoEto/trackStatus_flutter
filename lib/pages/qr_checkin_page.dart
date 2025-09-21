import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/user_service.dart';
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

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final userService = UserService();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.fromQrScan == true) {
      userService.streamUser("$uid");
    }
  }

  // ✅ บันทึกตอนครูกดยืนยัน
  Future<void> _submitAttendance() async {
    if (studentData == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final ref = FirebaseFirestore.instance
        .collection('Attendance')
        .doc('${studentData!['uid']}_$today');

    await ref.set({
      'studentId': studentData!['uid'],
      'studentCode': studentData!['studentCode'],
      'name': studentData!['name'],
      'status': _status,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกการเช็คชื่อเรียบร้อยแล้ว")),
      );
      Navigator.pop(context);
    }
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

  Future<void> _loadStudentData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      setState(() {
        studentData = doc.data();
      });
    }
  }

  Widget _buildStudentRow() {
    if (studentData == null) {
      return const Center(child: Text("ไม่มีข้อมูลนักเรียน"));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
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
                  studentData!['stuId'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  studentData!['name'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: "present",
              groupValue: _status,
              onChanged: (val) => setState(() => _status = val),
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: "leave",
              groupValue: _status,
              onChanged: (val) => setState(() => _status = val),
            ),
          ),
          Expanded(
            child: Radio<String>(
              value: "absent",
              groupValue: _status,
              onChanged: (val) => setState(() => _status = val),
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
          _buildStudentRow(),
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
              onPressed: _submitAttendance,
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
