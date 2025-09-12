import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⬅️ เพิ่ม

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _imageFile;
  bool _isLoading = false;
  final _plateCtrl = TextEditingController();

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    // ต้องเลือกรูปก่อน
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกรูปก่อน")));
      return;
    }

    // ต้องมีผู้ใช้ที่ล็อกอิน (anonymous ก็ได้)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังไม่ได้ล็อกอิน (anonymous)")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = user.uid;
    final fileName = 'bus_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('users/$uid/$fileName');

    try {
      // 1) อัปโหลดไฟล์ไป Storage
      await ref.putFile(
        _imageFile!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 2) ขอ URL
      final url = await ref.getDownloadURL();

      // 3) อัปเดต Users/{uid}.busImg (+ busPlate ถ้ากรอก)
      final plate = _plateCtrl.text.trim();
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'busImg': url,
        if (plate.isNotEmpty) 'busPlate': plate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปโหลดรูปและบันทึกไปที่ Users.busImg สำเร็จ ✅'),
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: [${e.code}] ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มรถ / อัปโหลดรูป")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: _imageFile == null
                    ? const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _plateCtrl,
              decoration: InputDecoration(
                labelText: "ป้ายทะเบียน",
                prefixIcon: const Icon(
                  Icons.directions_car,
                  color: Colors.teal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.cloud_upload),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("อัปโหลด & บันทึก"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
