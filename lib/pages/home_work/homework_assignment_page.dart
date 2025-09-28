import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../utils/notification_helper.dart';

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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDueDate;
  String? _selectedSubject;
  List<String> _assignedStudentIds = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      await _firestore.collection('Subjects').get();
      // Here you would populate subjects, but for now this is just initialization
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
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
      // Get all students from the database
      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'student')
          .get();

      List<Map<String, dynamic>> students = studentSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.get('name') ?? 'ไม่ระบุชื่อ',
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
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกนักเรียน: $e')),
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
      // Get current user
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher name
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String teacherName = userDoc.get('name') ?? 'ไม่ระบุชื่อ';

      // Create assignment document
      String assignmentId = _firestore.collection('Assignments').doc().id;
      await _firestore.collection('Assignments').doc(assignmentId).set({
        'id': assignmentId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'dueDate': _selectedDueDate,
        'assignedDate': Timestamp.now(),
        'teacherId': user.uid,
        'teacherName': teacherName,
        'subjectId': _selectedSubject ?? 'general',
        'assignedStudentIds': _assignedStudentIds,
        'status': 'assigned',
      });

      // Call notification function
      await NotificationHelper.handleHomeworkAssigned(
        assignmentId: assignmentId,
        teacherId: user.uid,
        teacherName: teacherName,
        subjectId: _selectedSubject ?? 'general',
        subjectName: _selectedSubject ?? 'ทั่วไป',
        assignmentTitle: _titleController.text,
        assignmentDescription: _descriptionController.text,
        dueDate: _selectedDueDate!,
        assignedStudentIds: _assignedStudentIds,
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
          _selectedSubject = null;
        });
      }
    } catch (e) {
      debugPrint('Error assigning homework: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการมอบหมายการบ้าน: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('มอบหมายการบ้าน'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อการบ้าน';
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
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรายละเอียดการบ้าน';
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
                      if (_assignedStudentIds.isNotEmpty)
                        Text('${_assignedStudentIds.length} นักเรียนถูกเลือก')
                      else
                        const Text('ยังไม่ได้เลือกนักเรียน', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _selectStudents,
                        icon: const Icon(Icons.people),
                        label: const Text('เลือกนักเรียน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Assign button
              ElevatedButton(
                onPressed: _assignHomework,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('มอบหมายการบ้าน', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
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
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: selectedStudents.length,
          itemBuilder: (context, index) {
            final student = selectedStudents[index];
            return CheckboxListTile(
              title: Text(student['name']),
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(selectedStudents);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}