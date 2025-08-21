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

      // ลบรูปใน Storage ด้วย
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
        title: const Text("ข้อมูลรถ"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("vehicles")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(child: Text("ยังไม่มีข้อมูลรถ"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var vehicle = data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vehicle['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    vehicle['licensePlate'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                      "เพิ่มเมื่อ: ${vehicle['createdAt']?.toDate() ?? ''}"),
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
                                licensePlate: vehicle['licensePlate'],
                                imageUrl: vehicle['imageUrl'],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(vehicle.id, vehicle['imageUrl']),
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
