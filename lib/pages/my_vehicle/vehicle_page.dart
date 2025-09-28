import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/vehicle_service.dart';
import 'vehicle_add_page.dart';
import 'vehicle_edit_page.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VehicleService _vehicleService = VehicleService();

  // ฟังก์ชันลบข้อมูล
  Future<void> _deleteVehicle(String vehicleId, String imageUrl) async {
    try {
      await _vehicleService.deleteVehicle(vehicleId, imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ลบข้อมูลเรียบร้อย")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการลบ: $e")),
        );
      }
    }
  }

  // Popup ยืนยันการลบ
  void _confirmDelete(String vehicleId, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลรถนี้?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle(vehicleId, imageUrl);
            },
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
  }

  // Show dialog to select vehicle type
  void _showVehicleTypeSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("เลือกประเภทรถที่ต้องการเพิ่ม"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text("รถส่วนตัว"),
                subtitle: const Text("ต้องได้รับการยืนยันจากผู้ปกครอง"),
                onTap: () async {
                  Navigator.pop(context);
                  // Check if user is parent to confirm personal vehicle
                  await _confirmPersonalVehicle();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.green),
                title: const Text("รถโรงเรียน"),
                subtitle: const Text("สำหรับพนักงานขับรถโรงเรียน"),
                onTap: () {
                  Navigator.pop(context);
                  // Directly navigate to add school vehicle
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleAddPage(isSchoolVehicle: true)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm personal vehicle with parent verification
  Future<void> _confirmPersonalVehicle() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเข้าสู่ระบบก่อน")),
        );
      }
      return;
    }

    // Get user role using service
    String? userRole = await _vehicleService.getUserRole(currentUser.uid);

    if (userRole == 'parent') {
      // If user is parent, allow directly
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VehicleAddPage(isPersonalVehicle: true)),
      );
    } else {
      // For other roles, show confirmation dialog
      bool confirmed = await _showParentConfirmationDialog();
      if (confirmed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehicleAddPage(isPersonalVehicle: true)),
        );
      }
    }
  }

  // Show dialog to confirm parent will verify personal vehicle
  Future<bool> _showParentConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ยืนยันการเพิ่มรถส่วนตัว"),
          content: const Text(
            "คุณกำลังจะเพิ่มรถส่วนตัว ซึ่งจำเป็นต้องได้รับการยืนยันจากผู้ปกครองอีกครั้ง "
            "คุณต้องการดำเนินการต่อหรือไม่?"
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Return false
              },
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text("ยืนยัน"),
            ),
          ],
        );
      },
    );
    return result ?? false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลรถ"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _vehicleService.getVehicles(),
        builder: (context, snapshot) {
          // กรณีมีข้อผิดพลาด
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "เกิดข้อผิดพลาดในการโหลดข้อมูล",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          // กรณีกำลังโหลดข้อมูล
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ตรวจสอบว่า snapshot มีข้อมูลหรือไม่
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "ยังไม่มีข้อมูลรถ",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "กดปุ่ม + เพื่อเพิ่มรถ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // แสดงรายการรถ
          final data = snapshot.data!.docs;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var vehicle = data[index];
              // ตรวจสอบ null safety สำหรับข้อมูลจาก Firestore
              final licensePlate = vehicle['licensePlate'] as String? ?? 'ไม่ระบุ';
              final imageUrl = vehicle['imageUrl'] as String? ?? '';
              final isSchoolVehicle = vehicle['isSchoolVehicle'] as bool? ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      color: isSchoolVehicle ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: 60,
                    height: 60,
                    child: Icon(
                      isSchoolVehicle ? Icons.directions_bus : Icons.directions_car,
                      color: isSchoolVehicle ? Colors.green : Colors.blue,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    licensePlate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    isSchoolVehicle ? "รถโรงเรียน" : "รถส่วนตัว",
                    style: TextStyle(
                      color: isSchoolVehicle ? Colors.green : Colors.blue,
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VehicleEditPage(
                                vehicleId: vehicle.id,
                                licensePlate: licensePlate,
                                imageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(vehicle.id, imageUrl),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: _showVehicleTypeSelection,
      ),
    );
  }
}