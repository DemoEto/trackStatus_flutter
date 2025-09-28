import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

import '../../routes/app_route.dart';
import '../../utils/notification_helper.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false; // กันซ้ำ

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
        
        NotificationHelper.handleStudentClassCheckin(
          studentId: currentUserId,
          studentName: studentName,
          subjectId: subjectId,
          subjectName: subjectName,
        );
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
      
      NotificationHelper.handleStudentSchoolArrival(
        studentId: studentId,
        studentName: studentName,
      );
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
      
      NotificationHelper.handleStudentSchoolDeparture(
        studentId: studentId,
        studentName: studentName,
      );
    } catch (e) {
      debugPrint('Error handling school departure: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Scanner"),
        centerTitle: true,
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
                    
                    // ไปหน้า /qrCheckin
                    context.push('/qrCheckinScan/${code.split("/")[1]}/${code.split("/")[2]}');
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
                      context.go(AppRoutes.home); // ใช้ go() เพื่อ replace ไป home
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
