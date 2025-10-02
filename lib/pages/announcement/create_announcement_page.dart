import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/announcement_service.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _announcementService = AnnouncementService();
  
  bool _isImportant = false;
  List<String> _selectedRoles = ['student', 'parent', 'driver'];
  String? _senderRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get user role using UserService
      String? userRole = await UserService().getUserRole(user.uid);
      setState(() {
        _senderRole = userRole;
      });
    }
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _announcementService.createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
        senderRole: _senderRole ?? 'teacher',
        targetRoles: _selectedRoles,
        isImportant: _isImportant,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แจ้งเตือนประชาสัมพันธ์ถูกสร้างเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form and navigate back
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _isImportant = false;
          _selectedRoles = ['student', 'parent', 'driver'];
        });
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'หัวข้อ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกหัวข้อ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'เนื้อหา',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเนื้อหา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Importance toggle
              Row(
                children: [
                  Checkbox(
                    value: _isImportant,
                    onChanged: (value) {
                      setState(() {
                        _isImportant = value ?? false;
                      });
                    },
                  ),
                  const Text('แจ้งเตือนสำคัญ'),
                ],
              ),
              const SizedBox(height: 16),
              // Target roles selection
              const Text('ส่งถึง:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: [
                  FilterChip(
                    label: const Text('นักเรียน'),
                    selected: _selectedRoles.contains('student'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add('student');
                        } else {
                          _selectedRoles.remove('student');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('ผู้ปกครอง'),
                    selected: _selectedRoles.contains('parent'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add('parent');
                        } else {
                          _selectedRoles.remove('parent');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('คนขับรถ'),
                    selected: _selectedRoles.contains('driver'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add('driver');
                        } else {
                          _selectedRoles.remove('driver');
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createAnnouncement,
                icon: const Icon(Icons.send),
                label: const Text('สร้างแจ้งเตือน'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
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
    _contentController.dispose();
    super.dispose();
  }
}