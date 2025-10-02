import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for parent to get bus tracking notifications for their children
  Stream<QuerySnapshot> getParentBusTrackingStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Get the user document to find their children
    return _firestore
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      List<dynamic>? children = userDoc.get('children') as List<dynamic>?;
      if (children == null || children.isEmpty) {
        // Return empty query if no children
        return await _firestore
            .collection('Notifications')
            .where('type', isEqualTo: 'bus_tracking')
            .where('recipientId', isEqualTo: user.uid) // Only notifications for this parent
            .orderBy('timestamp', descending: true)
            .limit(10) // Limit to recent notifications
            .get();
      }

      // Get bus tracking notifications related to their children
      return await _firestore
          .collection('Notifications')
          .where('type', isEqualTo: 'bus_tracking')
          .where('recipientId', isEqualTo: user.uid) // Notifications for this parent
          .orderBy('timestamp', descending: true)
          .get();
    });
  }

  // Stream for student to get their own bus tracking notifications
  Stream<QuerySnapshot> getStudentBusTrackingStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('Notifications')
        .where('type', isEqualTo: 'bus_tracking')
        .where('recipientId', isEqualTo: user.uid) // Notifications for this student
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}