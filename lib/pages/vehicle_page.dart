import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final TextEditingController _licensePlateController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  /// เลือกรูปจากแกลเลอรี
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// อัปโหลดข้อมูลรถขึ้น Firebase
  Future<void> _uploadVehicle() async {
    if (_licensePlateController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกป้ายทะเบียนและเลือกรูป")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // อัปโหลดรูปไปยัง Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child("vehicles/$fileName.jpg")
          .putFile(_imageFile!);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // บันทึกข้อมูลลง Firestore
      await FirebaseFirestore.instance.collection("vehicles").add({
        "licensePlate": _licensePlateController.text.trim(),
        "imageUrl": downloadUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อย")),
      );

      _licensePlateController.clear();
      setState(() {
        _imageFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มข้อมูลรถ"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // แสดงรูปภาพ
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
                          child: Icon(Icons.add_a_photo,
                              size: 60, color: Colors.teal),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ช่องกรอกป้ายทะเบียน
              TextField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: "ป้ายทะเบียนรถ",
                  prefixIcon: const Icon(Icons.directions_car, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadVehicle,
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("บันทึกข้อมูล"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
