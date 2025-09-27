import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleEditPage extends StatefulWidget {
  const VehicleEditPage({super.key});

  @override
  State<VehicleEditPage> createState() => _VehicleEditPageState();
}

class _VehicleEditPageState extends State<VehicleEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();

  String _vehicleType = "รถโรงเรียน";
  String? _currentImgUrl;
  File? _newImageFile;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  // ===== helpers =====
  FirebaseStorage _storageForCurrentApp() {
    // ใช้บัคเก็ตจริงของโปรเจกต์คุณ
    return FirebaseStorage.instanceFor(
      bucket: 'gs://trackstatus-flutter.appspot.com',
    );
  }

  String _guessMimeType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<void> _loadCurrent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("ยังไม่ได้ล็อกอิน")));
        Navigator.pop(context);
        return;
      }

      final snap =
          await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      final data = (snap.data() ?? {});
      _plateCtrl.text = (data['carPlate'] ?? '') as String;
      _currentImgUrl = (data['carImg'] ?? '') as String;
      final busId = (data['busId'] ?? '') as String;
      _vehicleType = busId == 'privateCar' ? "รถส่วนตัว" : "รถโรงเรียน";
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("โหลดข้อมูลไม่สำเร็จ: $e")));
      Navigator.pop(context);
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("ยังไม่ได้ล็อกอิน")));
      return;
    }

    setState(() => _saving = true);

    String? imageUrl = _currentImgUrl;

    try {
      // ถ้ามีรูปใหม่ → อัปโหลด + ได้ URL ใหม่
      if (_newImageFile != null) {
        final ext = _newImageFile!.path.split('.').last;
        final ref = _storageForCurrentApp()
            .ref()
            .child('users/${user.uid}/car_${DateTime.now().millisecondsSinceEpoch}.$ext');

        final meta =
            SettableMetadata(contentType: _guessMimeType(_newImageFile!.path));
        final snap = await ref.putFile(_newImageFile!, meta);
        if (snap.totalBytes == 0) {
          throw FirebaseException(
              plugin: 'firebase_storage',
              code: 'upload-empty',
              message: 'ไฟล์อัปโหลดเป็น 0 ไบต์');
        }
        imageUrl = await ref.getDownloadURL(); // URL String

        // ลบรูปเก่าถ้ามี
        final old = _currentImgUrl;
        if (old != null && old.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(old).delete();
          } catch (_) {
            // เงียบ ๆ ถ้าลบไม่ได้
          }
        }
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'carImg': imageUrl ?? '',
        'carPlate': _plateCtrl.text.trim(),
        'busId': _vehicleType == "รถโรงเรียน" ? "schoolBus" : "privateCar",
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลสำเร็จ ✅")));
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("บันทึกไม่สำเร็จ: [${e.code}] ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("บันทึกไม่สำเร็จ: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขข้อมูลรถ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: "ประเภทรถ"),
                items: const [
                  DropdownMenuItem(value: "รถโรงเรียน", child: Text("รถโรงเรียน")),
                  DropdownMenuItem(value: "รถส่วนตัว", child: Text("รถส่วนตัว")),
                ],
                onChanged: (v) => setState(() => _vehicleType = v ?? "รถโรงเรียน"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _plateCtrl,
                decoration: InputDecoration(
                  labelText: "ป้ายทะเบียน",
                  prefixIcon:
                      const Icon(Icons.directions_car, color: Colors.teal),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "กรุณากรอกทะเบียนรถ" : null,
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
                  child: _newImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child:
                              Image.file(_newImageFile!, fit: BoxFit.cover),
                        )
                      : (_currentImgUrl ?? '').isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                _currentImgUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) =>
                                    const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 64)),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image,
                                  size: 64, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("บันทึกการแก้ไข"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
