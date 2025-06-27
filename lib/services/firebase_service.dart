import 'package:cloud_firestore/cloud_firestore.dart';


void createUser() async{
  
  final usersRef = FirebaseFirestore.instance.collection('users');
  // 1. ดึง users ที่ขึ้นต้นด้วย "std" แล้วเรียงลำดับตาม docId
  final querySnapshot = await usersRef
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'std')
      .where(FieldPath.documentId, isLessThanOrEqualTo: 'std\uf8ff')
      .orderBy(FieldPath.documentId, descending: true)
      .limit(1)
      .get();

  String newId;
  if (querySnapshot.docs.isEmpty) {
    newId = 'std001';
  } else {
    final lastId = querySnapshot.docs.first.id; // เช่น std007
    final lastNumber = int.parse(lastId.replaceAll(RegExp(r'[^0-9]'), ''));
    final nextNumber = lastNumber + 1;
    newId = 'std${nextNumber.toString().padLeft(3, '0')}'; // std008
  }

  // 2. เพิ่มผู้ใช้ด้วย ID ที่ generate
  await usersRef.doc(newId).set({
    'name': 'John',
    'email': 'john@example.com',
    'age': 25,
  });
}

void deleteUser(String docId) async{
  FirebaseFirestore.instance.collection('users').doc(docId).delete();
}