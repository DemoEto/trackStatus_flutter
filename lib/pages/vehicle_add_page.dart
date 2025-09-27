import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// เพิ่มข้อมูลรถ + อัปโหลดรูปไป Firebase Storage
/// Firestore: Users/{uid} → carImg (URL String), carPlate, busId
class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  /// ประเภทรถ (UI) → map เป็น busId: "privateCar" | "schoolBus"
  String _vehicleType = "รถส่วนตัว";

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90, // ลดขนาดนิดหน่อยให้อัพโหลดเร็วขึ้น
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  /// ใช้ **บัคเก็ตจริงของโปรเจกต์** เสมอ (กันสลับโปรเจกต์/Emulator)
  FirebaseStorage _storageForCurrentApp() {
    return FirebaseStorage.instanceFor(
      bucket:
          'gs://trackstatus-flutter.appspot.com', // <- ตรวจให้ตรงกับ Console
    );
  }

  /// เดาจากนามสกุลไฟล์ เพื่อใส่ contentType ถูกต้อง
  String _guessMimeType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  /// รีทราย getDownloadURL() เผื่อ latency/consistency หลังอัปโหลด
  Future<String> _safeGetDownloadURL(Reference ref) async {
    const tries = 3;
    for (int i = 0; i < tries; i++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found' && i < tries - 1) {
          await Future.delayed(Duration(milliseconds: 300 * (1 << i)));
          continue;
        }
        rethrow;
      }
    }
    return await ref.getDownloadURL();
  }

  /// บันทึกข้อมูลรถ + อัปโหลดรูป (carImg เก็บเป็น URL String)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกรูปรถก่อน")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ยังไม่ได้ล็อกอิน")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = user.uid;
      final ext = _imageFile!.path.split('.').last;
      final fileName = 'car_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final storage = _storageForCurrentApp();
      debugPrint('📦 Using bucket: ${storage.bucket}');
      final ref = storage.ref().child('users/$uid/$fileName');
      // 1) อัปโหลดไฟล์
      final metadata = SettableMetadata(
        contentType: _guessMimeType(_imageFile!.path),
      );
      // final snapshot = await ref.putFile(_imageFile!, metadata);

      // if (snapshot.totalBytes == 0) {
      //   throw FirebaseException(
      //     plugin: 'firebase_storage',
      //     code: 'upload-empty',
      //     message: 'ไฟล์อัปโหลดเป็น 0 ไบต์',
      //   );
      // }

      // debugPrint('✅ Upload done → bucket=${snapshot.ref.bucket} path=${snapshot.ref.fullPath} bytes=${snapshot.totalBytes}');

      // // 2) ยืนยันว่ามีอ็อบเจ็กต์จริง + ขอ URL (มีรีทราย)
      // await snapshot.ref.getMetadata();
      // final String url = await _safeGetDownloadURL(snapshot.ref); // <-- URL String
      // debugPrint('🔗 Download URL = $url');

      // // 3) บันทึกเข้า Firestore → Users/{uid}
      // await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      //   'carImg': url,                                   // <-- String URL
      //   'carPlate': _plateCtrl.text.trim(),
      //   'busId': _vehicleType == "รถโรงเรียน" ? "schoolBus" : "privateCar",
      //   'createdAt': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // }, SetOptions(merge: true));

      // if (!mounted) return;
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลรถสำเร็จ ✅')));
      // Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final code = e.code;
      final msg = e.message ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อัปโหลดไม่สำเร็จ: [$code] $msg'
            '\n• ตรวจใน Console > Storage ว่ามีไฟล์ตาม path ใน log หรือไม่'
            '\n• ตรวจว่า bucket ใน log ตรงกับ Console'
            '\n• ถ้าเคยใช้ Emulator ให้คอมเมนต์ useStorageEmulator ออก',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มข้อมูลรถ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _vehicleType, // ใช้ initialValue (แทน value)
                decoration: const InputDecoration(labelText: "ประเภทรถ"),
                items: const [
                  DropdownMenuItem(
                    value: "รถส่วนตัว",
                    child: Text("รถส่วนตัว"),
                  ),
                  DropdownMenuItem(
                    value: "รถโรงเรียน",
                    child: Text("รถโรงเรียน"),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _vehicleType = v ?? "รถส่วนตัว"),
              ),
              const SizedBox(height: 12),

              TextFormField(
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "กรุณากรอกป้ายทะเบียน"
                    : null,
              ),
              const SizedBox(height: 16),

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
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.cloud_upload),
                  label: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
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
      ),
    );
  }
}
