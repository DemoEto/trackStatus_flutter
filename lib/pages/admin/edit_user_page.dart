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

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = "student";

  // Role-specific fields
  final _classRoomController = TextEditingController(); // student
  final _busIdController = TextEditingController(); // student
  final _phoneController = TextEditingController(); // for all users
  final _childrenController = TextEditingController(); // parent
  final _drvIdController = TextEditingController(); // driver
  final _subIdController = TextEditingController(); // teacher

  bool _isLoading = true;
  
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _classRoomController.dispose();
    _busIdController.dispose();
    _phoneController.dispose();
    _childrenController.dispose();
    _drvIdController.dispose();
    _subIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await _userService.getUserById(widget.uid);
      if (userData != null) {
        _idController.text = userData['id']?.toString() ?? "";
        _nameController.text = userData['name']?.toString() ?? "";
        _role = userData['role']?.toString() ?? "student";
        _phoneController.text = userData['phone']?.toString() ?? "";

        // Role-specific fields
        _classRoomController.text = userData['classRoomId']?.toString() ?? "";
        _busIdController.text = userData['busId']?.toString() ?? "";
        _childrenController.text = (userData['children'] != null)
            ? (userData['children'] as List<dynamic>).cast<String>().join(", ")
            : "";

        _drvIdController.text = userData['drvId']?.toString() ?? "";
        _subIdController.text = userData['subId']?.toString() ?? "";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้: ${e.toString()}")),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _userService.updateUser(
        userId: widget.uid,
        role: _role,
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        classRoomId: _classRoomController.text.trim(),
        busId: _busIdController.text.trim(),
        phone: _phoneController.text.trim(),
        children: _childrenController.text.isEmpty 
            ? [] 
            : _childrenController.text.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        drvId: _drvIdController.text.trim(),
        subId: _subIdController.text.trim(),
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
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขผู้ใช้"),
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
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "ID",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอก ID';
                    }
                    if (value.trim().length < 2) {
                      return 'ID ต้องมีอย่างน้อย 2 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อ",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อ';
                    }
                    if (value.trim().length < 2) {
                      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "เบอร์โทรศัพท์",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: "บทบาท",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "student", child: Text("นักเรียน")),
                    DropdownMenuItem(value: "parent", child: Text("ผู้ปกครอง")),
                    DropdownMenuItem(value: "driver", child: Text("คนขับรถ")),
                    DropdownMenuItem(value: "teacher", child: Text("ครู")),
                    DropdownMenuItem(value: "admin", child: Text("ผู้ดูแลระบบ")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _role = val);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'กรุณาเลือกบทบาท';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role-specific forms
                if (_role == "student") ...[
                  TextFormField(
                    controller: _classRoomController,
                    decoration: const InputDecoration(
                      labelText: "รหัสห้องเรียน",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _busIdController,
                    decoration: const InputDecoration(
                      labelText: "รหัสรถบัส",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (_role == "parent") ...[
                  TextFormField(
                    controller: _childrenController,
                    decoration: const InputDecoration(
                      labelText: "รหัสนักเรียน (คั่นด้วย ,)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 3,
                  ),
                ] else if (_role == "driver") ...[
                  TextFormField(
                    controller: _drvIdController,
                    decoration: const InputDecoration(
                      labelText: "รหัสคนขับ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (_role == "teacher") ...[
                  TextFormField(
                    controller: _subIdController,
                    decoration: const InputDecoration(
                      labelText: "รหัสวิชา",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "บันทึก",
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
