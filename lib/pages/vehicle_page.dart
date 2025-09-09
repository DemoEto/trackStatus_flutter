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
  // ลบข้อมูล + กันเคส imageUrl ว่าง/ลบไม่ได้
  Future<void> _deleteVehicle(String vehicleId, String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection("vehicles").doc(vehicleId).delete();

      if (imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (_) {
          // เงียบ ๆ ถ้าลบรูปไม่ได้ (เช่น ไม่มีไฟล์/สิทธิ์ไม่พอ)
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบข้อมูลเรียบร้อย")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการลบ: $e")),
      );
    }
  }

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

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("ยังไม่มีข้อมูลรถ", style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text("กดปุ่ม + เพื่อเพิ่มรถ", style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("vehicles")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลรถ"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          // กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // มีข้อผิดพลาด
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();

            // ถ้าเป็น permission denied ให้แสดง empty-state ตามที่ต้องการ
            if (msg.contains('PERMISSION_DENIED') ||
                msg.contains('permission-denied') ||
                msg.contains('Missing or insufficient permissions')) {
              return _emptyState();
            }

            // เคสอื่น ๆ แสดงข้อความผิดพลาดไว้เพื่อแก้ไข
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "เกิดข้อผิดพลาดในการโหลดข้อมูล:\n$msg",
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ไม่มีข้อมูล
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _emptyState();
          }

          // แสดงรายการ
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final vehicle = docs[index].data();

              final licensePlate = (vehicle['licensePlate'] as String?)?.trim().isNotEmpty == true
                  ? vehicle['licensePlate'] as String
                  : 'ไม่ระบุ';

              final imageUrl = (vehicle['imageUrl'] as String?) ?? '';

              // รองรับหลายชนิดข้อมูลของ createdAt
              String createdAtText = 'ไม่ระบุ';
              final raw = vehicle['createdAt'];
              if (raw is Timestamp) {
                createdAtText = raw.toDate().toString();
              } else if (raw is DateTime) {
                createdAtText = raw.toString();
              } else if (raw is String) {
                createdAtText = raw;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              Icons.broken_image, size: 60, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                  title: Text(
                    licensePlate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text("เพิ่มเมื่อ: $createdAtText"),
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
                                vehicleId: docs[index].id,
                                licensePlate: licensePlate,
                                imageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(docs[index].id, imageUrl),
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
            MaterialPageRoute(builder: (context) => const UploadImagePage()),
          );
        },
      ),
    );
  }
}
