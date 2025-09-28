import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement_model.dart';
import '../utils/notification_helper.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get announcementsCollection => _firestore.collection('Announcements');

  // Create a new announcement
  Future<String> createAnnouncement({
    required String title,
    required String content,
    required String senderName,
    required String senderRole,
    List<String> targetRoles = const ['student', 'parent', 'driver'],
    bool isImportant = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has permission to create announcements (teacher or admin)
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? userRole = userDoc.get('role') as String?;
      
      if (userRole != 'teacher' && userRole != 'admin') {
        throw Exception('Only teachers and admins can create announcements');
      }

      // Create announcement document
      String announcementId = announcementsCollection.doc().id;
      Announcement announcement = Announcement(
        id: announcementId,
        title: title,
        content: content,
        senderId: user.uid,
        senderName: senderName,
        senderRole: senderRole,
        targetRoles: targetRoles,
        timestamp: DateTime.now(),
        isImportant: isImportant,
      );

      await announcementsCollection.doc(announcementId).set(announcement.toMap());

      // Send notifications to target roles
      for (String role in targetRoles) {
        await NotificationHelper.sendAnnouncementToRole(
          role: role,
          title: title,
          content: content,
          senderName: senderName,
        );
      }

      return announcementId;
    } catch (e) {
      print('Error creating announcement: $e');
      rethrow;
    }
  }

  // Get all announcements
  Stream<List<Announcement>> getAllAnnouncements() {
    return announcementsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get announcements for current user based on their role
  Stream<List<Announcement>> getUserAnnouncements() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // First get the user's role
    return _firestore.collection('Users').doc(user.uid).snapshots().asyncMap((userDoc) async {
      String? userRole = userDoc.get('role') as String?;
      if (userRole == null) return <Announcement>[];

      // Then get announcements that target this user's role
      QuerySnapshot announcementsSnapshot = await announcementsCollection
          .where('targetRoles', arrayContains: userRole)
          .orderBy('timestamp', descending: true)
          .get();
          
      return announcementsSnapshot.docs
          .map((doc) => Announcement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Check if current user can create announcements
  Future<bool> canCreateAnnouncements() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
    String? userRole = userDoc.get('role') as String?;
    
    return userRole == 'teacher' || userRole == 'admin';
  }
}