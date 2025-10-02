import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../models/notification_model.dart' as app_models;

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final UserService _userService = UserService();
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

      // Get sender name using UserService
      Map<String, dynamic>? userData = await _userService.getUserById(user.uid);
      String senderName = userData?['name'] ?? 'ไม่ทราบชื่อ';

      final notificationService = NotificationService();
      
      List<String> rolesToSend = _selectedRole == 'all' 
          ? ['student', 'parent', 'teacher', 'driver'] 
          : [_selectedRole];

      for (String role in rolesToSend) {
        // Get users by role using UserService
        QuerySnapshot? usersSnapshot;
        await for (var snapshot in _userService.getUsersByRole(role)) {
          usersSnapshot = snapshot;
          break; // Get the first snapshot
        }

        if (usersSnapshot != null) {
          for (var userDoc in usersSnapshot.docs) {
            // Get the user's device token to send push notification
            String? deviceToken = userDoc.get('fcmToken') as String?;

            // Create a Firestore notification for each user in this role
            String notificationId = await notificationService.createFirestoreNotification(
              title: _titleController.text,
              body: _bodyController.text,
              type: 'admin_notification',
              senderId: user.uid,
              senderName: senderName,
              recipientId: userDoc.id,
              payload: {
                'adminId': user.uid,
                'timestamp': Timestamp.now().toDate().toString(),
              },
            );

            // Send push notification to the user if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: _titleController.text,
                body: _bodyController.text,
                data: {
                  'type': 'admin_notification',
                  'notificationId': notificationId,
                  'adminId': user.uid,
                },
              );
            }
          }
        }
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
        title: const Text('Notification Management'),
        centerTitle: true,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    final NotificationService notificationService = NotificationService();
    return StreamBuilder<QuerySnapshot>(
      stream: notificationService.getAllNotifications(),
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