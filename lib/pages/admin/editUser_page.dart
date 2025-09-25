import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _idCtrl.text = data['id'] ?? "";
      _nameCtrl.text = data['name'] ?? "";
      _role = data['role'] ?? "";

      // role-based
      _classRoomCtrl.text = data['classRoomId'] ?? "";
      _busIdCtrl.text = data['busId'] ?? "";
      _childrenCtrl.text = (data['children'] != null)
          ? (data['children'] as List<dynamic>).cast<String>().join(",")
          : "";

      _drvIdCtrl.text = data['drvId'] ?? "";
      _subIdCtrl.text = data['subId'] ?? "";
    }

    setState(() => _loading = false);
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final updateData = {
      "id": _idCtrl.text,
      "name": _nameCtrl.text,
      "role": _role,
    };
    _childrenCtrl.text == _childrenCtrl.text
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    if (_role == "student") {
      updateData["classRoomId"] = _classRoomCtrl.text;
      updateData["busId"] = _busIdCtrl.text;
    } else if (_role == "parent") {
      updateData["children"] = _childrenCtrl.text;
    } else if (_role == "driver") {
      updateData["drvId"] = _drvIdCtrl.text;
    } else if (_role == "teacher") {
      updateData["subId"] = _subIdCtrl.text;
    }

    // safer than update()
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.uid)
        .set(updateData, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
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
