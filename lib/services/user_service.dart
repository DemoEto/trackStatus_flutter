import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(userId).get();
      return userDoc.get('role') as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user by ID (returning Map instead of UserModel)
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get current user's role
  Future<String?> getCurrentUserRole() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return await getUserRole(currentUser.uid);
    }
    return null;
  }

  // Get users by role
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore
        .collection('Users')
        .where('role', isEqualTo: role)
        .snapshots();
  }

  // Get children of a parent
  Future<List<String>?> getChildrenOfParent(String parentId) async {
    try {
      DocumentSnapshot parentDoc = await _firestore.collection('Users').doc(parentId).get();
      if (!parentDoc.exists) return null;
      
      List<dynamic>? children = parentDoc.get('children');
      return children?.cast<String>();
    } catch (e) {
      print('Error getting children of parent: $e');
      return null;
    }
  }

  // Get students assigned to a bus
  Stream<QuerySnapshot> getStudentsOnBus(String busId) {
    return _firestore
        .collection('Users')
        .where('busId', isEqualTo: busId)
        .where('role', isEqualTo: 'student')
        .snapshots();
  }
  
  // Stream user data
  Stream<StudentData?> streamUser(String userId) {
    return _firestore.collection('Users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return StudentData(
        name: data['name'] ?? '',
        role: data['role'] ?? '',
        busId: data['busId'] ?? '',
        stdId: data['stdId'] ?? '',
      );
    });
  }
  
  // Stream user role
  Stream<String?> streamUserRole() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return _firestore.collection('Users').doc(currentUser.uid).snapshots().map((doc) => doc.get('role'));
    }
    return const Stream.empty();
  }
  
  // Start attendance notification service (placeholder)
  void startAttendanceNotificationService() {
    // This is a placeholder for now - implementation depends on the specific service
  }
}