import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/notification_helper.dart';

class HomeworkSubmissionPage extends StatefulWidget {
  const HomeworkSubmissionPage({super.key});

  @override
  State<HomeworkSubmissionPage> createState() => _HomeworkSubmissionPageState();
}

class _HomeworkSubmissionPageState extends State<HomeworkSubmissionPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การบ้านที่ต้องส่ง'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getCurrentUserAssignments(),
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
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีการบ้านที่ต้องส่ง',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final assignments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _buildAssignmentCard(assignment);
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getCurrentUserAssignments() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Get assignments assigned to this student
    return _firestore
        .collection('Assignments')
        .where('assignedStudentIds', arrayContains: user.uid)
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  Widget _buildAssignmentCard(DocumentSnapshot assignmentDoc) {
    final assignment = assignmentDoc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    final dueDate = (assignment['dueDate'] as Timestamp).toDate();
    final daysUntilDue = dueDate.difference(now).inDays;
    final isOverdue = daysUntilDue < 0;
    
    Color cardColor = Colors.white;
    if (isOverdue) {
      cardColor = Colors.red.shade50;
    } else if (daysUntilDue <= 2) {
      cardColor = Colors.orange.shade50;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assignment['title'] ?? 'ไม่มีชื่อการบ้าน',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'เลยกำหนด',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                else if (daysUntilDue <= 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${daysUntilDue} วัน',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              assignment['description'] ?? 'ไม่มีรายละเอียด',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'กำหนดส่ง: ${_formatDate(assignment['dueDate'] as Timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _submitHomework(assignmentDoc.id, assignment),
                  child: const Text('ส่งการบ้าน'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitHomework(String assignmentId, Map<String, dynamic> assignment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get student name
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String studentName = userDoc.get('name') ?? 'ไม่ระบุชื่อ';

      // Update assignment status for this student
      await _firestore.collection('Assignments')
          .doc(assignmentId)
          .collection('Submissions')
          .doc(user.uid)
          .set({
            'studentId': user.uid,
            'assignmentId': assignmentId,
            'submittedAt': Timestamp.now(),
            'status': 'submitted',
          });

      // Call notification function for homework submission
      await NotificationHelper.handleHomeworkSubmitted(
        assignmentId: assignmentId,
        studentId: user.uid,
        studentName: studentName,
        teacherId: assignment['teacherId'] ?? '',
        assignmentTitle: assignment['title'] ?? '',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งการบ้านเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      print('Error submitting homework: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งการบ้าน: $e')),
        );
      }
    }
  }
}