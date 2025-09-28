import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String type; // 'attendance_update', 'public_announcement', 'bus_tracking', 'homework', etc.
  final String senderId;
  final String senderName;
  final String recipientId; // User who receives this notification
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload; // Additional data specific to notification type

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      recipientId: data['recipientId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      payload: data['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'timestamp': timestamp,
      'isRead': isRead,
      'payload': payload,
    };
  }
}