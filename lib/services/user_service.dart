import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new user
  Future<void> addUser({
    required String role,
    required String id,
    required String name,
    String? busId,
    String? classRoomId,
    String? phone,
    List<String>? children,
    String? subId,
    String? drvId,
  }) async {
    try {
      await _firestore.collection('Users').add({
        'role': role,
        'id': id,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        // Conditional fields based on role
        if (role == 'student' && busId != null) ...{
          'busId': busId,
          'classRoomId': classRoomId,
        },
        if (role == 'parent' && phone != null) ...{
          'phone': phone,
          'children': children,
        },
        if (role == 'teacher' && subId != null) ...{
          'subId': subId,
        },
        if (role == 'driver' && busId != null && phone != null) ...{
          'busId': busId,
          'phone': phone,
          if (drvId != null) 'drvId': drvId,
        },
      });
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  // Update an existing user
  Future<void> updateUser({
    required String userId,
    String? role,
    String? id,
    String? name,
    String? busId,
    String? classRoomId,
    String? phone,
    List<String>? children,
    String? subId,
    String? drvId,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (role != null) updateData['role'] = role;
      if (id != null) updateData['id'] = id;
      if (name != null) updateData['name'] = name;
      
      // Conditional fields based on role
      if (role == 'student') {
        if (busId != null) updateData['busId'] = busId;
        if (classRoomId != null) updateData['classRoomId'] = classRoomId;
      } else if (role == 'parent') {
        if (phone != null) updateData['phone'] = phone;
        if (children != null) updateData['children'] = children;
      } else if (role == 'teacher') {
        if (subId != null) updateData['subId'] = subId;
      } else if (role == 'driver') {
        if (busId != null) updateData['busId'] = busId;
        if (phone != null) updateData['phone'] = phone;
        if (drvId != null) updateData['drvId'] = drvId;
      }

      await _firestore.collection('Users').doc(userId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('Users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

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

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('Users').snapshots();
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
  
  // Check if current user is authorized to perform attendance
  Future<bool> isAuthorizedForAttendance() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .get();
          
      if (!userDoc.exists) {
        return false;
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? userRole = userData['role']?.toString();
      
      // Only allow teachers and admins to perform attendance
      return userRole == 'teacher' || userRole == 'admin';
    } catch (e) {
      print('Error checking attendance authorization: $e');
      return false;
    }
  }
  
  // Start attendance notification service (placeholder)
  void startAttendanceNotificationService() {
    // This is a placeholder for now - implementation depends on the specific service
  }
}