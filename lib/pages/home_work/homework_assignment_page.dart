import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show QuerySnapshot;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../services/assignment_service.dart';
import '../../services/user_service.dart';

class HomeworkAssignmentPage extends StatefulWidget {
  const HomeworkAssignmentPage({super.key});

  @override
  State<HomeworkAssignmentPage> createState() => _HomeworkAssignmentPageState();
}

class _HomeworkAssignmentPageState extends State<HomeworkAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  final AssignmentService _assignmentService = AssignmentService();
  final UserService _userService = UserService();
  final _auth = FirebaseAuth.instance;

  DateTime? _selectedDueDate;
  List<String> _assignedStudentIds = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectStudents() async {
    try {
      // Get all students from the database using UserService
      QuerySnapshot? studentSnapshot;
      await for (var snapshot in _userService.getUsersByRole('student')) {
        studentSnapshot = snapshot;
        break; // Get the first snapshot
      }

      if (studentSnapshot == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลนักเรียน')),
          );
        }
        return;
      }

      List<Map<String, dynamic>> students = studentSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.get('name')?.toString() ?? 'ไม่ระบุชื่อ',
                'selected': _assignedStudentIds.contains(doc.id)
              })
          .toList();

      // Show dialog to select students
      List<Map<String, dynamic>>? selectedStudents = 
          await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (context) => _StudentSelectionDialog(
          students: students,
        ),
      );

      if (selectedStudents != null) {
        setState(() {
          _assignedStudentIds = selectedStudents
              .where((student) => student['selected'] as bool)
              .map((student) => student['id'] as String)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error selecting students: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกนักเรียน: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _assignHomework() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันกำหนดส่ง')),
      );
      return;
    }

    if (_assignedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกนักเรียนที่ต้องการมอบหมายการบ้าน')),
      );
      return;
    }

    try {
      // Get current user and teacher name using UserService
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher name
      Map<String, dynamic>? userData = await _userService.getUserById(user.uid);
      String teacherName = userData?['name']?.toString() ?? 'ไม่ระบุชื่อ';

      // Use AssignmentService to create assignment
      await _assignmentService.createAssignment(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDueDate!,
        assignedStudentIds: _assignedStudentIds,
        subjectId: 'default_subject', // TODO: Add subject selection functionality
        teacherId: user.uid,
        teacherName: teacherName,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('มอบหมายการบ้านเรียบร้อยแล้ว')),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _dueDateController.clear();
        setState(() {
          _selectedDueDate = null;
          _assignedStudentIds = [];
        });
      }
    } catch (e) {
      debugPrint('Error assigning homework: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการมอบหมายการบ้าน: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('มอบหมายการบ้าน'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (!await Navigator.maybePop(context)) {
              context.go('/');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อการบ้าน',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อการบ้าน';
                    }
                    if (value.trim().length < 3) {
                      return 'ชื่อการบ้านต้องมีอย่างน้อย 3 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดการบ้าน',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรายละเอียดการบ้าน';
                    }
                    if (value.trim().length < 10) {
                      return 'รายละเอียดการบ้านต้องมีอย่างน้อย 10 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Due date selection
                TextFormField(
                  controller: _dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'วันกำหนดส่ง',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectDueDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวันกำหนดส่ง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Student selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'นักเรียนที่ได้รับการบ้าน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _assignedStudentIds.isNotEmpty 
                              ? '${_assignedStudentIds.length} นักเรียนถูกเลือก' 
                              : 'ยังไม่ได้เลือกนักเรียน',
                          style: TextStyle(
                            color: _assignedStudentIds.isNotEmpty 
                                ? Colors.black87 
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _selectStudents,
                            icon: const Icon(Icons.people),
                            label: const Text('เลือกนักเรียน'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Assign button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _assignHomework,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('มอบหมายการบ้าน', style: TextStyle(fontSize: 16)),
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

class _StudentSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const _StudentSelectionDialog({required this.students});

  @override
  State<_StudentSelectionDialog> createState() => _StudentSelectionDialogState();
}

class _StudentSelectionDialogState extends State<_StudentSelectionDialog> {
  late List<Map<String, dynamic>> selectedStudents;

  @override
  void initState() {
    super.initState();
    selectedStudents = List.from(widget.students);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลือกนักเรียน'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: selectedStudents.length,
          itemBuilder: (context, index) {
            final student = selectedStudents[index];
            return CheckboxListTile(
              title: Text(student['name'].toString()),
              value: student['selected'],
              onChanged: (bool? value) {
                setState(() {
                  student['selected'] = value ?? false;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedStudents),
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}