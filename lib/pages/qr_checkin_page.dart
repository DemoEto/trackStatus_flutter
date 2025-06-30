import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../routes/app_route.dart';

class QrCheckinPage extends StatefulWidget {
  const QrCheckinPage({super.key});

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  String? selectedStatus;

  Widget _stuList({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300, // สีของเส้นใต้
              width: 1.0, // ความหนา
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงรหัสนักเรียน + ชื่อ
            Text(
              '${'665433210004-8'} - ${'MR.Kanatip'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // แถวเลือกสถานะมาเรียน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRadio("present", "มา"),
                _buildRadio("late", "สาย"),
                _buildRadio("leave", "ลา"),
                _buildRadio("absent", "ขาด"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง radio ปุ่ม
  Widget _buildRadio(String value, String label) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedStatus,
          onChanged: (newValue) {
            setState(() {
              selectedStatus = newValue;
            });
          },
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR & Check-In')),
      body: 
          ListView(
            children: [
              _stuList(
                title: '66543210004-8', 
                subtitle: 'MR.Kanatip Wongkiti'
              ),
            ],
          ),

    );
  }
}
