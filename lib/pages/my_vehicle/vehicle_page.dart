import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Delete vehicle data
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
          SnackBar(content: Text("เกิดข้อผิดพลาดในการลบ: ${e.toString()}")),
        );
      }
    }
  }

  // Confirmation dialog for deletion
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
          TextButton(
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
                  context.push('/vehicle/add', extra: {'isSchoolVehicle': true});
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
      context.push('/vehicle/add', extra: {'isPersonalVehicle': true});
    } else {
      // For other roles, show confirmation dialog
      bool confirmed = await _showParentConfirmationDialog();
      if (confirmed) {
        context.push('/vehicle/add', extra: {'isPersonalVehicle': true});
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
            TextButton(
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (!await Navigator.maybePop(context)) {
              context.go('/');
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _vehicleService.getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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

          final vehicles = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final licensePlate = vehicle.get('licensePlate')?.toString() ?? 'ไม่ระบุ';
              final imageUrl = vehicle.get('imageUrl')?.toString() ?? '';
              final isSchoolVehicle = vehicle.get('isSchoolVehicle') as bool? ?? false;
              final vehicleType = vehicle.get('type')?.toString() ?? (isSchoolVehicle ? 'school' : 'personal');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSchoolVehicle ? Colors.green : Colors.blue,
                    width: 1.0,
                  ),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSchoolVehicle ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSchoolVehicle ? Colors.green : Colors.blue,
                        ),
                      ),
                      child: Icon(
                        isSchoolVehicle ? Icons.directions_bus : Icons.directions_car,
                        color: isSchoolVehicle ? Colors.green : Colors.blue,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      licensePlate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      isSchoolVehicle ? "รถโรงเรียน" : "รถส่วนตัว",
                      style: TextStyle(
                        color: isSchoolVehicle ? Colors.green : Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () {
                            context.push('/vehicle/edit', extra: {
                              'vehicleId': vehicle.id,
                              'licensePlate': licensePlate,
                              'imageUrl': imageUrl,
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(vehicle.id, imageUrl),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showVehicleTypeSelection,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}