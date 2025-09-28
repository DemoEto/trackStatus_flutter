import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String senderId;
  final String senderName;
  final String senderRole; // teacher, admin, etc.
  final List<String> targetRoles; // ['student', 'parent', 'driver']
  final DateTime timestamp;
  final bool isImportant;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.targetRoles = const ['student', 'parent', 'driver'],
    required this.timestamp,
    this.isImportant = false,
  });

  // Convert from Firestore document
  factory Announcement.fromMap(Map<String, dynamic> data) {
    return Announcement(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      targetRoles: List<String>.from(data['targetRoles'] ?? ['student', 'parent', 'driver']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isImportant: data['isImportant'] ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'targetRoles': targetRoles,
      'timestamp': timestamp,
      'isImportant': isImportant,
    };
  }
}