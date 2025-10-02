import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/attendance_service.dart';

class AddAttendancePage extends StatefulWidget {
  const AddAttendancePage({super.key});

  @override
  State<AddAttendancePage> createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
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
        studentId: _studentIdController.text.trim(),
        name: _nameController.text.trim(),
        subId: _subjectController.text.trim(),
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
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
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
          child: SingleChildScrollView(
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
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรหัสนักเรียน';
                    }
                    if (value.trim().length < 3) {
                      return 'รหัสนักเรียนต้องมีอย่างน้อย 3 ตัวอักษร';
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
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อนักเรียน';
                    }
                    if (value.trim().length < 2) {
                      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
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
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรหัสวิชา';
                    }
                    if (value.trim().length < 2) {
                      return 'รหัสวิชาต้องมีอย่างน้อย 2 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
                    FilterChip(
                      label: const Text('ลากิจ'),
                      selected: _status == 'leave_because_of_business',
                      onSelected: (selected) {
                        setState(() {
                          _status = selected ? 'leave_because_of_business' : _status;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('ลาป่วย'),
                      selected: _status == 'leave_because_of_sickness',
                      onSelected: (selected) {
                        setState(() {
                          _status = selected ? 'leave_because_of_sickness' : _status;
                        });
                      },
                    ),
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
                const Text('ประเภท', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
                    FilterChip(
                      label: const Text('เข้าโรงเรียน'),
                      selected: _type == 'school_in',
                      onSelected: (selected) {
                        setState(() {
                          _type = selected ? 'school_in' : _type;
                        });
                      },
                    ),
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
      ),
    );
  }
}