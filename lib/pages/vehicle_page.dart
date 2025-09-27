import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'vehicle_add_page.dart';   // UploadImagePage
import 'vehicle_edit_page.dart';  // VehicleEditPage

class VehiclePage extends StatelessWidget {
  const VehiclePage({super.key});

  Future<void> _clearVehicle(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final img = (data['carImg'] ?? '') as String;

      if (img.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(img).delete();
        } catch (_) {/* ignore */}
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'carImg': '',
        'carPlate': '',
        'busId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ลบข้อมูลรถแล้ว")));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ลบไม่สำเร็จ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลรถของฉัน"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("ยังไม่ได้ล็อกอิน"))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() ?? {};
                final String carImg = (data['carImg'] as String?) ?? '';   // <-- URL String
                final String carPlate = (data['carPlate'] as String?) ?? '';
                final String busId = (data['busId'] as String?) ?? '';
                final createdAt = data['createdAt'];
                String createdAtText = '—';
                if (createdAt is Timestamp) createdAtText = createdAt.toDate().toString();

                final hasData = carImg.isNotEmpty || carPlate.isNotEmpty || busId.isNotEmpty;

                if (!hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.directions_car, size: 80, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("ยังไม่มีข้อมูลรถ", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 6),
                        Text("กดปุ่ม + เพื่อเพิ่มข้อมูล", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final typeLabel = busId == 'privateCar'
                    ? "รถส่วนตัว"
                    : (busId == 'schoolBus' ? "รถโรงเรียน" : "ไม่ระบุ");

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (carImg.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                carImg,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => const SizedBox(
                                  height: 200,
                                  child: Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                                ),
                              ),
                            )
                          else
                            const SizedBox(
                              height: 200,
                              child: Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ป้ายทะเบียน: ${carPlate.isEmpty ? 'ไม่ระบุ' : carPlate}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text("ประเภทรถ: $typeLabel"),
                                const SizedBox(height: 8),
                                Text("เพิ่มเมื่อ: $createdAtText"),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const VehicleEditPage()),
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text("แก้ไข"),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("ยืนยันการลบ"),
                                            content: const Text("ต้องการลบข้อมูลรถนี้หรือไม่?"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ยกเลิก")),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                child: const Text("ลบ"),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        if (ok == true) _clearVehicle(context);
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text("ลบ", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadImagePage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
