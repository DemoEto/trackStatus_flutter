import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final AttendanceService _attendanceService = AttendanceService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ประวัติการแสกน"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Try to pop first, if that doesn't work, go home
            bool? result = await Navigator.of(context).maybePop();
            if (result != true) {
              // If maybePop didn't work, navigate to home
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Month selection header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 197, 211, 232), // Theme color
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMMM yyyy', 'th_TH').format(_selectedMonth)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _selectMonth,
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('เลือกเดือน'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // History list - different approach for different roles
          Expanded(
            child: FutureBuilder<String?>(
              future: _auth.currentUser != null ? _userService.getUserRole(_auth.currentUser!.uid) : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                String? userRole = snapshot.data;
                return userRole == 'parent' 
                    ? _buildParentAttendanceHistory()
                    : _buildGeneralAttendanceHistory();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build attendance history for parent role (showing children's attendance)
  Widget _buildParentAttendanceHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _userService.getUserById(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
        }

        List<dynamic> children = userSnapshot.data!['children'] ?? [];
        if (children.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ไม่มีข้อมูลนักเรียน',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate start and end of selected month
        DateTime startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        DateTime endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

        // For the whereIn query, we need to handle the 10-item limit
        // If we have more than 10 children, we'll need to fetch them in batches
        // For simplicity, we'll use a FutureBuilder approach instead of StreamBuilder
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getParentAttendanceHistory(children.cast<String>()),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${futureSnapshot.error}'));
            }

            if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'ไม่มีประวัติการแสกนในเดือนนี้',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            List<QueryDocumentSnapshot> allDocs = futureSnapshot.data!;
            
            // Sort all docs by timestamp descending
            allDocs.sort((a, b) {
              Map<String, dynamic>? aData = a.data() as Map<String, dynamic>?;
              Map<String, dynamic>? bData = b.data() as Map<String, dynamic>?;
              Timestamp? aTimestamp = aData?['timestamp'] as Timestamp?;
              Timestamp? bTimestamp = bData?['timestamp'] as Timestamp?;
              if (aTimestamp == null || bTimestamp == null) return 0;
              return bTimestamp.compareTo(aTimestamp);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allDocs.length,
              itemBuilder: (context, index) {
                final record = allDocs[index];
                Map<String, dynamic> data = record.data() as Map<String, dynamic>;
                
                Timestamp? timestamp = data['timestamp'] as Timestamp?;
                DateTime date = timestamp?.toDate() ?? DateTime.now();
                String status = data['status'] ?? 'ไม่ทราบสถานะ';
                String studentName = data['name'] ?? 'ไม่ทราบชื่อ';
                String studentId = data['studentId'] ?? 'ไม่ทราบ ID';

                Color statusColor = _getStatusColor(status);
                IconData statusIcon = _getStatusIcon(status);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ชื่อนักเรียน: $studentName',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'รหัสนักเรียน: $studentId',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วันที่: ${DateFormat('dd/MM/yyyy HH:mm', 'th_TH').format(date)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Build general attendance history for other roles
  Widget _buildGeneralAttendanceHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }

    // Calculate start and end of selected month
    DateTime startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // For student role, show their own attendance; for other roles, we'll need different logic
    return FutureBuilder<String?>(
      future: _userService.getUserRole(user.uid),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        String? userRole = roleSnapshot.data;
        String userId = userRole == 'student' ? user.uid : user.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: _attendanceService.getAttendanceForStudent(userId, startOfMonth, endOfMonth),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'ไม่มีประวัติการแสกนในเดือนนี้',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final attendanceRecords = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                Map<String, dynamic> data = record.data() as Map<String, dynamic>;
                
                Timestamp? timestamp = data['timestamp'] as Timestamp?;
                DateTime date = timestamp?.toDate() ?? DateTime.now();
                String status = data['status'] ?? 'ไม่ทราบสถานะ';
                String studentName = data['name'] ?? 'ไม่ทราบชื่อ';
                String studentId = data['studentId'] ?? 'ไม่ทราบ ID';

                Color statusColor = _getStatusColor(status);
                IconData statusIcon = _getStatusIcon(status);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ชื่อนักเรียน: $studentName',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'รหัสนักเรียน: $studentId',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วันที่: ${DateFormat('dd/MM/yyyy HH:mm', 'th_TH').format(date)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'leave':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'leave':
        return Icons.pending_actions;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'มาเรียน';
      case 'leave':
        return 'ลาเรียน';
      case 'absent':
        return 'ขาดเรียน';
      default:
        return status;
    }
  }
  
  // Helper method to get parent's children attendance history
  // This handles the Firestore whereIn() limit of 10 items
  Future<List<QueryDocumentSnapshot>> _getParentAttendanceHistory(List<String> childrenIds) async {
    if (childrenIds.isEmpty) return [];
    
    // Calculate start and end of selected month
    DateTime startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    // Use the service to get attendance records
    return await _attendanceService.getAttendanceForStudents(
      childrenIds,
      startOfMonth,
      endOfMonth,
    );
  }
}