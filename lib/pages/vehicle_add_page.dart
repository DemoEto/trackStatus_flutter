import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกรูปก่อน")));
      return;
    }
    setState(() => _isLoading = true);

    final fileName = 'veh_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('vehicles/$fileName');

    try {
      // 1) อัปโหลด
      await ref.putFile(
        _imageFile!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 2) ขอ URL (ต้องผ่าน rules read)
      final url = await ref.getDownloadURL();

      // 3) เขียนเข้า collection ที่หน้ารายการใช้อยู่ (vehicles)
      await FirebaseFirestore.instance.collection('vehicles').add({
        'licensePlate': _plateCtrl.text.trim(),
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกเรียบร้อย ✅')));
      Navigator.pop(context); // กลับไปหน้ารายการรถ
    } on FirebaseException catch (e) {
      // แยก error ให้รู้ว่า fail ตรงไหน
      final code = e.code;
      String where = 'unknown';
      if (e.message?.contains('getDownloadURL') == true)
        where = 'getDownloadURL';
      if (e.message?.contains('putFile') == true) where = 'upload';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด ($where): [${e.code}] ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e')));
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
