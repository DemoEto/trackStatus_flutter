import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:trackstatus_flutter/routes/app_route.dart';

class AttendanceManamentPage extends StatelessWidget {
  const AttendanceManamentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Management")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Attendance').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendance = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Student ID")),
                DataColumn(label: Text("Subject ID")),
                DataColumn(label: Text("Type")),
                DataColumn(label: Text("Timestamp")),
                DataColumn(label: Text("Actions")),
              ],
              rows: List<DataRow>.generate(attendance.length, (index) {
                final doc = attendance[index];
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(Text(data['id'] ?? '')),
                    DataCell(Text(data['subId'] ?? '')),
                    DataCell(Text(data['type'] ?? '')),
                    DataCell(Text(data['timestamp'] ?? '')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // TODO: ทำฟอร์มแก้ไข
                              context.push('/editAttendance/${doc.id}');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('Attendance')
                                  .doc(doc.id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to perform when the FAB is pressed
          context.push(AppRoutes.addAttendance);
        },
        child: Icon(Icons.add), // The icon displayed on the FAB
      ),
    );
  }
}
