import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';

class AttendHistoryPage extends StatefulWidget {
  const AttendHistoryPage({super.key});

  @override
  State<AttendHistoryPage> createState() => _AttendHistoryPageState();
}

class _AttendHistoryPageState extends State<AttendHistoryPage> {
  final AttendanceService _attendanceService = AttendanceService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedMonth = DateTime.now();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        String? role = await _userService.getUserRole(user.uid);
        setState(() {
          _userRole = role;
        });
      } catch (e) {
        debugPrint('Error loading user role: $e');
      }
    }
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
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
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
        title: const Text('ประวัติการแสกน'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Month selection header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMMM yyyy', 'th_TH').format(_selectedMonth)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectMonth,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('เลือกเดือน'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // History list - different approach for different roles
          Expanded(
            child: _userRole == 'parent' 
                ? _buildParentAttendanceHistory()
                : _buildGeneralAttendanceHistory(),
          ),
        ],
      ),
    );
  }

  // Build attendance history for parent role (showing children's attendance)
  Widget _buildParentAttendanceHistory() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _auth.currentUser != null 
          ? FirebaseFirestore.instance.collection('Users').doc(_auth.currentUser!.uid).snapshots()
          : null,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
        }

        List<dynamic> children = userSnapshot.data!.get('children') ?? [];
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
    String userId = _userRole == 'student' ? user.uid : user.uid;

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