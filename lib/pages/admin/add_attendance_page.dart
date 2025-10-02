import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/attendance_service.dart';

class AddattendancePage extends StatefulWidget {
  const AddattendancePage({super.key});

  @override
  State<AddattendancePage> createState() => _AddattendancePageState();
}

class _AddattendancePageState extends State<AddattendancePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _status = "present";
  String _type = "class_in";
  bool _isLoading = false;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void dispose() {
  _studentIdController.dispose();
  _nameController.dispose();
  _subjectController.dispose();
  super.dispose();
  }

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      await _attendanceService.addAttendance(
        studentId: _studentIdController.text,
        name: _nameController.text,
        subId: _subjectController.text,
        type: _type,
        status: _status,
        teacherId: user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลการมาเรียนเรียบร้อย')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Attendance'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'รหัสนักเรียน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสนักเรียน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อนักเรียน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อนักเรียน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'รหัสวิชา',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสวิชา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('สถานะ'),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  FilterChip(
                    label: const Text('มา'),
                    selected: _status == 'present',
                    onSelected: (selected) {
                      setState(() {
                        _status = selected ? 'present' : _status;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ลากิจ'),
                    selected: _status == 'leave',
                    onSelected: (selected) {
                      setState(() {
                        _status = selected ? 'leave' : _status;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ลาป่วย'),
                    selected: _status == 'leave',
                    onSelected: (selected) {
                      setState(() {
                        _status = selected ? 'leave' : _status;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ขาด'),
                    selected: _status == 'absent',
                    onSelected: (selected) {
                      setState(() {
                        _status = selected ? 'absent' : _status;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('ประเภท'),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  FilterChip(
                    label: const Text('เข้าเรียน'),
                    selected: _type == 'class_in',
                    onSelected: (selected) {
                      setState(() {
                        _type = selected ? 'class_in' : _type;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('เข้าโรงเรียน'),
                    selected: _type == 'school_in',
                    onSelected: (selected) {
                      setState(() {
                        _type = selected ? 'school_in' : _type;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ออกจากโรงเรียน'),
                    selected: _type == 'school_out',
                    onSelected: (selected) {
                      setState(() {
                        _type = selected ? 'school_out' : _type;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}