import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedUserType; // Dropdown value
  final List<String> _userTypes = [
    'student',
    'teacher',
    'admin',
    'driver',
    'parent',
  ];

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _busIdController = TextEditingController();
  final TextEditingController _classRoomIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _subIdController = TextEditingController();

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate() && _selectedUserType != null) {
      try {
        await FirebaseFirestore.instance.collection('Users').add({
          'role': _selectedUserType,
          'id': _idController.text,
          'name': _nameController.text,
          'createdAt': FieldValue.serverTimestamp(),
          // เงื่อนไขตาม role
          if (_selectedUserType == 'student') ...{
            'busId': _busIdController.text,
            'classRoomId': _classRoomIdController.text,
          },
          if (_selectedUserType == 'parent') ...{
            'phone': _phoneController.text,
            'children': _childrenController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(), // 🔥 กลายเป็น array
          },
          if (_selectedUserType == 'teacher') ...{
            'subId': _subIdController.text,
          },
          if (_selectedUserType == 'driver') ...{
            'busId': _busIdController.text,
            'phone': _phoneController.text,
          },
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedUserType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add user: $e')));
      }
    } else if (_selectedUserType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select user type')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedUserType,
                decoration: const InputDecoration(labelText: 'User Type'),
                items: _userTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a user type' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID'),
                validator: (value) => value!.isEmpty ? 'Please enter ID' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter name' : null,
              ),

              //!TODO: show by role
              //*Student
              if (_selectedUserType == 'student') ...[
                TextFormField(
                  controller: _busIdController,
                  decoration: const InputDecoration(labelText: 'Bus ID'),
                ),
                TextFormField(
                  controller: _classRoomIdController,
                  decoration: const InputDecoration(labelText: 'Classroom ID'),
                ),
              ],

              //*Parent
              if (_selectedUserType == 'parent') ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _childrenController,
                  decoration: const InputDecoration(labelText: 'Children'),
                ),
              ],

              //*Teacher
              if (_selectedUserType == 'teacher') ...[
                TextFormField(
                  controller: _subIdController,
                  decoration: const InputDecoration(labelText: 'subId'),
                ),
              ],
              //*Driver
              if (_selectedUserType == 'driver') ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'phone'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addUser,
                child: const Text('Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
