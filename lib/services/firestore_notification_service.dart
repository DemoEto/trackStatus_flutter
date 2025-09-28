import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class FirestoreNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get notificationsCollection => _firestore.collection('Notifications');

  // Create and store a notification
  Future<String> createNotification({
    required String title,
    required String body,
    required String type,
    required String senderId,
    required String senderName,
    required String recipientId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      String notificationId = notificationsCollection.doc().id;
      Notification notification = Notification(
        id: notificationId,
        title: title,
        body: body,
        type: type,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        timestamp: DateTime.now(),
        payload: payload,
      );

      await notificationsCollection.doc(notificationId).set(notification.toMap());
      return notificationId;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get notifications for current user
  Stream<List<Notification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return notificationsCollection
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot unreadNotifications = await notificationsCollection
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        await notificationsCollection.doc(doc.id).update({'isRead': true});
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}