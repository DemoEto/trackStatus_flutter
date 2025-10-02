import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class EditUserPage extends StatefulWidget {
  final String uid;
  const EditUserPage({super.key, required this.uid});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = "student";

  // ฟิลด์พิเศษ
  final _classRoomCtrl = TextEditingController(); // student
  final _busIdCtrl = TextEditingController(); // student
  final _childrenCtrl = TextEditingController(); // parent
  final _drvIdCtrl = TextEditingController(); // driver
  final _subIdCtrl = TextEditingController(); // teacher

  bool _loading = true;
  
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      Map<String, dynamic>? userData = await _userService.getUserById(widget.uid);
      if (userData != null) {
        _idCtrl.text = userData['id'] ?? "";
        _nameCtrl.text = userData['name'] ?? "";
        _role = userData['role'] ?? "";

        // role-based
        _classRoomCtrl.text = userData['classRoomId'] ?? "";
        _busIdCtrl.text = userData['busId'] ?? "";
        _childrenCtrl.text = (userData['children'] != null)
            ? (userData['children'] as List<dynamic>).cast<String>().join(",")
            : "";

        _drvIdCtrl.text = userData['drvId'] ?? "";
        _subIdCtrl.text = userData['subId'] ?? "";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้: $e")),
        );
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _userService.updateUser(
        userId: widget.uid,
        role: _role,
        id: _idCtrl.text,
        name: _nameCtrl.text,
        classRoomId: _classRoomCtrl.text,
        busId: _busIdCtrl.text,
        children: _childrenCtrl.text.isEmpty 
            ? [] 
            : _childrenCtrl.text.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        drvId: _drvIdCtrl.text,
        subId: _subIdCtrl.text,
        phone: _childrenCtrl.text, // Using childrenCtrl.text as phone for parent/driver roles
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกข้อมูลผู้ใช้เรียบร้อย")),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขผู้ใช้")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idCtrl,
                decoration: const InputDecoration(labelText: "ID"),
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: "Role"),
                items: const [
                  DropdownMenuItem(value: "student", child: Text("Student")),
                  DropdownMenuItem(value: "parent", child: Text("Parent")),
                  DropdownMenuItem(value: "driver", child: Text("Driver")),
                  DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _role = val);
                  }
                },
              ),

              const SizedBox(height: 16),

              // 🔹 ฟอร์มเพิ่มเติมตาม role
              if (_role == "student") ...[
                TextFormField(
                  controller: _classRoomCtrl,
                  decoration: const InputDecoration(labelText: "Class Room ID"),
                ),
                TextFormField(
                  controller: _busIdCtrl,
                  decoration: const InputDecoration(labelText: "Bus ID"),
                ),
              ] else if (_role == "parent") ...[
                TextFormField(
                  controller: _childrenCtrl,
                  decoration: const InputDecoration(
                    labelText: "Children IDs (คั่นด้วย ,)",
                  ),
                ),
              ] else if (_role == "driver") ...[
                TextFormField(
                  controller: _drvIdCtrl,
                  decoration: const InputDecoration(labelText: "Driver ID"),
                ),
              ] else if (_role == "teacher") ...[
                TextFormField(
                  controller: _subIdCtrl,
                  decoration: const InputDecoration(labelText: "Subject ID"),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveUser, child: const Text("บันทึก")),
            ],
          ),
        ),
      ),
    );
  }
}
