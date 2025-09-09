import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'vehicle_add_page.dart';
import 'vehicle_edit_page.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  // ฟังก์ชันลบข้อมูล
  Future<void> _deleteVehicle(String vehicleId, String imageUrl) async {
    try {
      // ลบเอกสารใน Firestore
      await FirebaseFirestore.instance.collection("vehicles").doc(vehicleId).delete();

      // ลบรูปใน Storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบข้อมูลเรียบร้อย")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการลบ: $e")),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลรถkkkkk"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("vehicles")
            .orderBy("createdAt", descending: true)
            .snapshots(),
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
              final createdAt = (vehicle['createdAt'] as Timestamp?)?.toDate().toString() ?? 'ไม่ระบุ';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                  title: Text(
                    licensePlate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text("เพิ่มเมื่อ: $createdAt"),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleEditPage(
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleAddPage()),
          );
        },
      ),
    );
  }
}