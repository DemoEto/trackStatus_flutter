import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/notification_helper.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get assignmentsCollection => _firestore.collection('Assignments');

  // Check for assignments due soon and send reminders
  Future<void> checkForAssignmentReminders() async {
    try {
      final now = Timestamp.now();
      final threeDaysFromNow = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 3)),
      );

      // Get assignments due in the next 3 days that haven't been submitted yet
      QuerySnapshot assignmentsSnapshot = await assignmentsCollection
          .where('dueDate', isLessThanOrEqualTo: threeDaysFromNow)
          .where('dueDate', isGreaterThanOrEqualTo: now)
          .get();

      for (var assignmentDoc in assignmentsSnapshot.docs) {
        Map<String, dynamic> assignment = assignmentDoc.data() as Map<String, dynamic>;
        
        // Get the students assigned to this assignment
        List<dynamic> assignedStudentIds = assignment['assignedStudentIds'] as List<dynamic>;
        
        for (String studentId in assignedStudentIds.cast<String>()) {
          // Check if student has already submitted
          DocumentSnapshot submissionDoc = await assignmentsCollection
              .doc(assignmentDoc.id)
              .collection('Submissions')
              .doc(studentId)
              .get();
              
          if (!submissionDoc.exists) {
            // Student hasn't submitted yet, send reminder
            int daysUntilDue = assignment['dueDate'].toDate().difference(DateTime.now()).inDays;
            
            await NotificationHelper.handleDeadlineReminder(
              assignmentId: assignment['id'] as String,
              studentId: studentId,
              studentName: await _getStudentName(studentId), // We'll implement this helper method
              assignmentTitle: assignment['title'] as String,
              subjectName: assignment['subjectId'] as String,
              dueDate: assignment['dueDate'].toDate(),
              daysRemaining: daysUntilDue,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for assignment reminders: $e');
    }
  }

  // Helper method to get student name
  Future<String> _getStudentName(String studentId) async {
    try {
      DocumentSnapshot studentDoc = await _firestore.collection('Users').doc(studentId).get();
      return studentDoc.get('name') as String? ?? 'นักเรียน';
    } catch (e) {
      print('Error getting student name: $e');
      return 'นักเรียน';
    }
  }

  // Check for overdue assignments and send notifications
  Future<void> checkForOverdueAssignments() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      // Get assignments that are overdue
      QuerySnapshot assignmentsSnapshot = await assignmentsCollection
          .where('dueDate', isLessThan: now)
          .get();

      for (var assignmentDoc in assignmentsSnapshot.docs) {
        Map<String, dynamic> assignment = assignmentDoc.data() as Map<String, dynamic>;
        
        // Get the students assigned to this assignment
        List<dynamic> assignedStudentIds = assignment['assignedStudentIds'] as List<dynamic>;
        
        for (String studentId in assignedStudentIds.cast<String>()) {
          // Check if student has already submitted
          DocumentSnapshot submissionDoc = await assignmentsCollection
              .doc(assignmentDoc.id)
              .collection('Submissions')
              .doc(studentId)
              .get();
              
          if (!submissionDoc.exists) {
            // Student hasn't submitted yet, send overdue notification
            await NotificationHelper.handleAssignmentOverdue(
              assignmentId: assignment['id'] as String,
              studentId: studentId,
              studentName: await _getStudentName(studentId),
              assignmentTitle: assignment['title'] as String,
              subjectName: assignment['subjectId'] as String,
              dueDate: assignment['dueDate'].toDate(),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for overdue assignments: $e');
    }
  }

  // Get assignments for current user
  Stream<List<QueryDocumentSnapshot>> getUserAssignments() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return assignmentsCollection
        .where('assignedStudentIds', arrayContains: user.uid)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}