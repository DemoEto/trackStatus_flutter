import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/notification_helper.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedRole = 'all'; // Default to sending to all users
  final List<String> _roles = ['all', 'student', 'teacher', 'parent', 'admin', 'driver'];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อและเนื้อหา')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get sender name
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      String senderName = userDoc.get('name') ?? 'ไม่ทราบชื่อ';

      if (_selectedRole == 'all') {
        // Send to all users
        await NotificationHelper.createNotificationForRole(
          role: 'student',
          title: _titleController.text,
          body: _bodyController.text,
          type: 'admin_notification',
          senderId: user.uid,
          senderName: senderName,
          payload: {
            'adminId': user.uid,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );
        
        await NotificationHelper.createNotificationForRole(
          role: 'parent',
          title: _titleController.text,
          body: _bodyController.text,
          type: 'admin_notification',
          senderId: user.uid,
          senderName: senderName,
          payload: {
            'adminId': user.uid,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );
        
        await NotificationHelper.createNotificationForRole(
          role: 'teacher',
          title: _titleController.text,
          body: _bodyController.text,
          type: 'admin_notification',
          senderId: user.uid,
          senderName: senderName,
          payload: {
            'adminId': user.uid,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );
        
        await NotificationHelper.createNotificationForRole(
          role: 'driver',
          title: _titleController.text,
          body: _bodyController.text,
          type: 'admin_notification',
          senderId: user.uid,
          senderName: senderName,
          payload: {
            'adminId': user.uid,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );
      } else {
        // Send to specific role
        await NotificationHelper.createNotificationForRole(
          role: _selectedRole,
          title: _titleController.text,
          body: _bodyController.text,
          type: 'admin_notification',
          senderId: user.uid,
          senderName: senderName,
          payload: {
            'adminId': user.uid,
            'timestamp': Timestamp.now().toDate().toString(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งการแจ้งเตือนสำเร็จ')),
        );
      }

      // Clear the form
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งการแจ้งเตือน: $e')),
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
        title: const Text('จัดการการแจ้งเตือน'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ส่งการแจ้งเตือน',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'หัวข้อการแจ้งเตือน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'เนื้อหาการแจ้งเตือน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'ส่งไปยัง',
                border: OutlineInputBorder(),
              ),
              items: _roles.map((role) {
                String displayText;
                switch (role) {
                  case 'all':
                    displayText = 'ทุกคน';
                    break;
                  case 'student':
                    displayText = 'นักเรียน';
                    break;
                  case 'teacher':
                    displayText = 'ครู';
                    break;
                  case 'parent':
                    displayText = 'ผู้ปกครอง';
                    break;
                  case 'admin':
                    displayText = 'ผู้ดูแลระบบ';
                    break;
                  case 'driver':
                    displayText = 'พนักงานขับรถ';
                    break;
                  default:
                    displayText = role;
                }
                return DropdownMenuItem(
                  value: role,
                  child: Text(displayText),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text(
                      'ส่งการแจ้งเตือน',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ประวัติการแจ้งเตือน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildNotificationHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ยังไม่มีประวัติการแจ้งเตือน'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(notification['title'] ?? 'ไม่มีหัวข้อ'),
                subtitle: Text(notification['body'] ?? 'ไม่มีเนื้อหา'),
                trailing: Text(
                  notification['timestamp']?.toDate().toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}