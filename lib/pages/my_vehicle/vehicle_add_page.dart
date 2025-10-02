import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/vehicle_service.dart';

class VehicleAddPage extends StatefulWidget {
  final bool isPersonalVehicle;
  final bool isSchoolVehicle;

  const VehicleAddPage({super.key, this.isPersonalVehicle = false, this.isSchoolVehicle = false});

  @override
  State<VehicleAddPage> createState() => _VehicleAddPageState();
}

class _VehicleAddPageState extends State<VehicleAddPage> {
  final TextEditingController _licensePlateController = TextEditingController();
  File? _imageFile;
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_licensePlateController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาใส่ป้ายทะเบียนและเลือกรูป")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image to Firebase Storage using the same approach
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child("vehicles/$fileName.jpg");
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Determine vehicle type based on parameter and save using VehicleService
      bool isPersonal = widget.isPersonalVehicle;
      bool isSchool = widget.isSchoolVehicle;
      
      await _vehicleService.addVehicle(
        licensePlate: _licensePlateController.text.trim(),
        imageUrl: downloadUrl,
        isPersonalVehicle: isPersonal,
        isSchoolVehicle: isSchool,
      );

      if (mounted) {
        String successMessage = isPersonal 
            ? "เพิ่มข้อมูลรถส่วนตัวเรียบร้อย\n(จำเป็นต้องได้รับการยืนยันจากผู้ปกครอง)" 
            : "บันทึกข้อมูลเรียบร้อย";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPersonal = widget.isPersonalVehicle;
    String appBarTitle = isPersonal ? "เพิ่มข้อมูลรถส่วนตัว" : "เพิ่มข้อมูลรถ";
    IconData appBarIcon = isPersonal ? Icons.directions_car : Icons.directions_bus;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                    border: Border.all(
                      color: isPersonal ? Colors.blue : Colors.green, 
                      width: 2
                    ),
                  ),
                  child: _imageFile == null
                      ? Icon(Icons.add_a_photo,
                          color: isPersonal ? Colors.blue : Colors.green, size: 50)
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
              TextField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: "ป้ายทะเบียนรถ",
                  prefixIcon: Icon(
                    isPersonal ? Icons.directions_car : Icons.directions_bus,
                    color: isPersonal ? Colors.blue : Colors.green
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isPersonal) ...[
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    border: Border.all(color: Colors.yellow.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.yellow.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "หมายเหตุ: ข้อมูลรถส่วนตัวนี้จะต้องได้รับการยืนยันจากผู้ปกครองก่อนจึงจะสามารถใช้งานได้",
                          style: TextStyle(
                            color: Colors.yellow.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveVehicle,
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isPersonal ? "บันทึกข้อมูล (ต้องยืนยัน)" : "บันทึกข้อมูล"),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
