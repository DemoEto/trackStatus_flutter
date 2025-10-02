import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';

// import '../../models/attendance_model.dart';

class EditAttendancePage extends StatefulWidget {
  final String attendanceId;
  const EditAttendancePage({super.key, required this.attendanceId});

  @override
  State<EditAttendancePage> createState() => _EditAttendancePageState();
}

class _EditAttendancePageState extends State<EditAttendancePage> {
  final _formKey = GlobalKey<FormState>();

  final _stdIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Added missing name controller
  final _subIdCtrl = TextEditingController();
  String _type = "class_in";
  String _status = "มา";
  bool _loading = true;
  
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _stdIdCtrl.dispose();
    _nameCtrl.dispose();
    _subIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    try {
      // In a real implementation, you would load the attendance data
      // For now, we'll just set loading to false
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e")),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _attendanceService.updateAttendance(
        attendanceId: widget.attendanceId,
        studentId: _stdIdCtrl.text,
        name: _nameCtrl.text,
        subId: _subIdCtrl.text,
        type: _type,
        status: _status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกข้อมูลการมาเรียนเรียบร้อย")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขข้อมูลการมาเรียน")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _stdIdCtrl,
                decoration: const InputDecoration(
                  labelText: "ID นักเรียน",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "กรุณากรอก ID นักเรียน";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "ชื่อนักเรียน",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "กรุณากรอกชื่อนักเรียน";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subIdCtrl,
                decoration: const InputDecoration(
                  labelText: "รหัสวิชา",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: "ประเภท",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "school_in", child: Text("มาโรงเรียน")),
                  DropdownMenuItem(value: "class_in", child: Text("เข้าเรียน")),
                  DropdownMenuItem(value: "school_out", child: Text("กลับบ้าน")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _type = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: "สถานะ",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "มา", child: Text("มาเรียน")),
                  DropdownMenuItem(value: "ลา", child: Text("ลากิจ")),
                  DropdownMenuItem(value: "ป่วย", child: Text("ลาป่วย")),
                  DropdownMenuItem(value: "ขาด", child: Text("ขาดเรียน")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("บันทึก", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}