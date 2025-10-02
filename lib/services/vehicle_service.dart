import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get vehicles with stream
  Stream<QuerySnapshot> getVehicles() {
    return _firestore
        .collection("vehicles")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Delete vehicle
  Future<void> deleteVehicle(String vehicleId, String imageUrl) async {
    try {
      // Delete document in Firestore
      await _firestore.collection("vehicles").doc(vehicleId).delete();

      // Delete image in Storage
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
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

  // Add a new vehicle
  Future<void> addVehicle({
    required String licensePlate,
    required String imageUrl,
    bool isPersonalVehicle = false,
    bool isSchoolVehicle = false,
  }) async {
    try {
      await _firestore.collection("vehicles").add({
        "licensePlate": licensePlate,
        "imageUrl": imageUrl,
        "isPersonalVehicle": isPersonalVehicle,
        "isSchoolVehicle": isSchoolVehicle,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  // Update an existing vehicle
  Future<void> updateVehicle({
    required String vehicleId,
    required String licensePlate,
    required String imageUrl,
  }) async {
    try {
      await _firestore.collection("vehicles").doc(vehicleId).update({
        "licensePlate": licensePlate,
        "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }
}