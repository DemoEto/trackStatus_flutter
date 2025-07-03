import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/student_model.dart';

class QrCheckinPage extends StatefulWidget {
  const QrCheckinPage({super.key});

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  
  final List<Student> students = [
    Student(id: '66543210004-8', name: 'MR.Kanatip Wongkiti'),
    Student(id: '66543210005-9', name: 'MISS.Supannee Yindeeta'),
    Student(id: '66543210006-0', name: 'MR.Chaiwat Promma'),
    Student(id: '66543210007-1', name: 'MISS.Pattama Saelim'),
    // เพิ่มนักเรียนคนอื่นๆ ได้ที่นี่
  ];

  Widget _buildStudentRow({required Student student}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300, // สีของเส้นใต้
            width: 1.0, // ความหนา
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 10.0), // PADDING นี้
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded( // ส่วนของ Text
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.id,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    student.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded( // ส่วนของ Radio buttons
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRadioForStudent(student, "present"),
                  _buildRadioForStudent(student, "leave"),
                  _buildRadioForStudent(student, "absent"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ฟังก์ชันสร้าง radio ปุ่มสำหรับนักเรียนแต่ละคน
  Widget _buildRadioForStudent(Student student, String value) {
    return SizedBox( // ใช้ Expanded เพื่อกระจายพื้นที่ให้เท่ากัน
        width:45,
        height: 45,
        child: 
          Radio<String>(
            value: value,
            groupValue: student.status, // ใช้สถานะของนักเรียนแต่ละคน
            onChanged: (newValue) {
              setState(() {
                student.status = newValue;
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR & Check-In')),
      body: Column(
        children: [
          // ส่วนหัวของตาราง: มา ลา ขาด
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0), // PADDING นี้
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Expanded(flex: 3, child: SizedBox.shrink()), // พื้นที่สำหรับชื่อ
                Expanded(child: Center(child: Text("มา", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("ลา", style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("ขาด", style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          // เส้นแบ่งส่วนหัวและรายการนักเรียน
          Divider(color: Colors.grey.shade400, height: 1, thickness: 1), 
          
          // รายการนักเรียน
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                return _buildStudentRow(student: students[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
