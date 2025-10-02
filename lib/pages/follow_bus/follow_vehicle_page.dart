import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../../services/notification_service.dart';

class FollowVehiclePage extends StatefulWidget {
  const FollowVehiclePage({super.key});

  @override
  State<FollowVehiclePage> createState() => _FollowVehiclePageState();
}

class _FollowVehiclePageState extends State<FollowVehiclePage> {
  String status = "";
  String? _userRole;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
        String? role = userDoc.get('role') as String?;
        if (mounted) {
          setState(() {
            _userRole = role;
          });
        }
      } catch (e) {
        debugPrint('Error loading user role: $e');
      }
    }
  }

  // Handle bus departure to school
  Future<void> _handleBusDepartureToSchool() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get driver's bus assignment
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      String? driverName = userDoc.get('name') as String?;
      if (busId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลรถของคุณ')),
          );
        }
        return;
      }

      // Get students assigned to this bus
      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .where('busId', isEqualTo: busId)
          .where('role', isEqualTo: 'student')
          .get();

      List<String> studentIds = studentSnapshot.docs.map((doc) => doc.id).toList();

      // Use NotificationService to send notifications to parents of these students
      final notificationService = NotificationService();
      for (String studentId in studentIds) {
        // Find parents of this student
        QuerySnapshot parentSnapshot = await _firestore
            .collection('Users')
            .where('role', isEqualTo: 'parent')
            .get();
            
        for (var parentDoc in parentSnapshot.docs) {
          List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
          if (children != null && children.contains(studentId)) {
            String? deviceToken = parentDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the parent
            String notificationId = await notificationService.createFirestoreNotification(
              title: 'รถโรงเรียนกำลังเดินทาง',
              body: 'รถโรงเรียนของคุณ $driverName กำลังเดินทางไปรับนักเรียนที่โรงเรียน',
              type: 'bus_tracking',
              senderId: user.uid,
              senderName: driverName ?? 'คนขับรถ',
              recipientId: parentDoc.id,
              payload: {
                'busId': busId,
                'driverId': user.uid,
                'studentId': studentId,
                'action': 'departure_to_school',
                'timestamp': Timestamp.now().toDate().toString(),
              },
            );

            // Send push notification to the parent if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: 'รถโรงเรียนกำลังเดินทาง',
                body: 'รถโรงเรียนของคุณ $driverName กำลังเดินทางไปรับนักเรียนที่โรงเรียน',
                data: {
                  'type': 'bus_tracking',
                  'notificationId': notificationId,
                  'busId': busId,
                  'studentId': studentId,
                  'action': 'departure_to_school',
                },
              );
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แจ้งเตือนการเดินทางไปโรงเรียนถูกส่งแล้ว')),
      );
    } catch (e) {
      debugPrint('Error handling bus departure to school: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Handle bus arrival at school
  Future<void> _handleBusArrivalAtSchool() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get driver's bus assignment
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      String? driverName = userDoc.get('name') as String?;
      if (busId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลรถของคุณ')),
          );
        }
        return;
      }

      // Get students assigned to this bus
      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .where('busId', isEqualTo: busId)
          .where('role', isEqualTo: 'student')
          .get();

      List<String> studentIds = studentSnapshot.docs.map((doc) => doc.id).toList();

      // Use NotificationService to send notifications to parents of these students
      final notificationService = NotificationService();
      for (String studentId in studentIds) {
        // Find parents of this student
        QuerySnapshot parentSnapshot = await _firestore
            .collection('Users')
            .where('role', isEqualTo: 'parent')
            .get();
            
        for (var parentDoc in parentSnapshot.docs) {
          List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
          if (children != null && children.contains(studentId)) {
            String? deviceToken = parentDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the parent
            String notificationId = await notificationService.createFirestoreNotification(
              title: 'รถโรงเรียนถึงโรงเรียนแล้ว',
              body: 'รถโรงเรียนของคุณ $driverName ได้ส่งนักเรียนถึงโรงเรียนเรียบร้อย',
              type: 'bus_tracking',
              senderId: user.uid,
              senderName: driverName ?? 'คนขับรถ',
              recipientId: parentDoc.id,
              payload: {
                'busId': busId,
                'driverId': user.uid,
                'studentId': studentId,
                'action': 'arrival_at_school',
                'timestamp': Timestamp.now().toDate().toString(),
              },
            );

            // Send push notification to the parent if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: 'รถโรงเรียนถึงโรงเรียนแล้ว',
                body: 'รถโรงเรียนของคุณ $driverName ได้ส่งนักเรียนถึงโรงเรียนเรียบร้อย',
                data: {
                  'type': 'bus_tracking',
                  'notificationId': notificationId,
                  'busId': busId,
                  'studentId': studentId,
                  'action': 'arrival_at_school',
                },
              );
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แจ้งเตือนการถึงโรงเรียนถูกส่งแล้ว')),
      );
    } catch (e) {
      debugPrint('Error handling bus arrival at school: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Handle bus departure to home
  Future<void> _handleBusDepartureToHome() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get driver's bus assignment
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      String? driverName = userDoc.get('name') as String?;
      if (busId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลรถของคุณ')),
          );
        }
        return;
      }

      // Get students assigned to this bus
      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .where('busId', isEqualTo: busId)
          .where('role', isEqualTo: 'student')
          .get();

      List<String> studentIds = studentSnapshot.docs.map((doc) => doc.id).toList();

      // Use NotificationService to send notifications to parents of these students
      final notificationService = NotificationService();
      for (String studentId in studentIds) {
        // Find parents of this student
        QuerySnapshot parentSnapshot = await _firestore
            .collection('Users')
            .where('role', isEqualTo: 'parent')
            .get();
            
        for (var parentDoc in parentSnapshot.docs) {
          List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
          if (children != null && children.contains(studentId)) {
            String? deviceToken = parentDoc.get('fcmToken') as String?;

            // Create a Firestore notification for the parent
            String notificationId = await notificationService.createFirestoreNotification(
              title: 'รถโรงเรียนกำลังเดินทางกลับบ้าน',
              body: 'รถโรงเรียนของคุณ $driverName กำลังเดินทางกลับบ้าน',
              type: 'bus_tracking',
              senderId: user.uid,
              senderName: driverName ?? 'คนขับรถ',
              recipientId: parentDoc.id,
              payload: {
                'busId': busId,
                'driverId': user.uid,
                'studentId': studentId,
                'action': 'departure_to_home',
                'timestamp': Timestamp.now().toDate().toString(),
              },
            );

            // Send push notification to the parent if device token is available
            if (deviceToken != null) {
              await notificationService.sendPushNotification(
                deviceToken: deviceToken,
                title: 'รถโรงเรียนกำลังเดินทางกลับบ้าน',
                body: 'รถโรงเรียนของคุณ $driverName กำลังเดินทางกลับบ้าน',
                data: {
                  'type': 'bus_tracking',
                  'notificationId': notificationId,
                  'busId': busId,
                  'studentId': studentId,
                  'action': 'departure_to_home',
                },
              );
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แจ้งเตือนการเดินทางกลับบ้านถูกส่งแล้ว')),
      );
    } catch (e) {
      debugPrint('Error handling bus departure to home: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Handle student pickup by bus
  Future<void> _handleStudentBusPickup(String studentId, String studentName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get driver's bus assignment
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      String? driverName = userDoc.get('name') as String?;
      if (busId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลรถของคุณ')),
          );
        }
        return;
      }

      // Use NotificationService to send notification to parent of this student
      final notificationService = NotificationService();
      QuerySnapshot parentSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'parent')
          .get();
          
      for (var parentDoc in parentSnapshot.docs) {
        List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
        if (children != null && children.contains(studentId)) {
          String? deviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String notificationId = await notificationService.createFirestoreNotification(
            title: 'รับนักเรียนขึ้นรถ',
            body: 'นักเรียน $studentName ได้ขึ้นรถของคุณ $driverName เรียบร้อยแล้ว',
            type: 'bus_tracking',
            senderId: user.uid,
            senderName: driverName ?? 'คนขับรถ',
            recipientId: parentDoc.id,
            payload: {
              'busId': busId,
              'driverId': user.uid,
              'studentId': studentId,
              'studentName': studentName,
              'action': 'student_pickup',
              'timestamp': Timestamp.now().toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (deviceToken != null) {
            await notificationService.sendPushNotification(
              deviceToken: deviceToken,
              title: 'รับนักเรียนขึ้นรถ',
              body: 'นักเรียน $studentName ได้ขึ้นรถของคุณ $driverName เรียบร้อยแล้ว',
              data: {
                'type': 'bus_tracking',
                'notificationId': notificationId,
                'busId': busId,
                'studentId': studentId,
                'studentName': studentName,
                'action': 'student_pickup',
              },
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('แจ้งเตือนการรับ $studentName ถูกส่งแล้ว')),
      );
    } catch (e) {
      debugPrint('Error handling student bus pickup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Handle student dropoff at home
  Future<void> _handleStudentBusDropoffAtHome(String studentId, String studentName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get driver's bus assignment
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      String? driverName = userDoc.get('name') as String?;
      if (busId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลรถของคุณ')),
          );
        }
        return;
      }

      // Use NotificationService to send notification to parent of this student
      final notificationService = NotificationService();
      QuerySnapshot parentSnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'parent')
          .get();
          
      for (var parentDoc in parentSnapshot.docs) {
        List<dynamic>? children = parentDoc.get('children') as List<dynamic>?;
        if (children != null && children.contains(studentId)) {
          String? deviceToken = parentDoc.get('fcmToken') as String?;

          // Create a Firestore notification for the parent
          String notificationId = await notificationService.createFirestoreNotification(
            title: 'ส่งนักเรียนถึงบ้าน',
            body: 'นักเรียน $studentName ถึงบ้านเรียบร้อยแล้ว',
            type: 'bus_tracking',
            senderId: user.uid,
            senderName: driverName ?? 'คนขับรถ',
            recipientId: parentDoc.id,
            payload: {
              'busId': busId,
              'driverId': user.uid,
              'studentId': studentId,
              'studentName': studentName,
              'action': 'student_dropoff',
              'timestamp': Timestamp.now().toDate().toString(),
            },
          );

          // Send push notification to the parent if device token is available
          if (deviceToken != null) {
            await notificationService.sendPushNotification(
              deviceToken: deviceToken,
              title: 'ส่งนักเรียนถึงบ้าน',
              body: 'นักเรียน $studentName ถึงบ้านเรียบร้อยแล้ว',
              data: {
                'type': 'bus_tracking',
                'notificationId': notificationId,
                'busId': busId,
                'studentId': studentId,
                'studentName': studentName,
                'action': 'student_dropoff',
              },
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('แจ้งเตือนการส่ง $studentName ถึงบ้านถูกส่งแล้ว')),
      );
    } catch (e) {
      debugPrint('Error handling student bus dropoff at home: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Get students assigned to current user's bus
  Future<List<Map<String, dynamic>>> _getStudentsOnBus() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      String? busId = userDoc.get('busId') as String?;
      if (busId == null) return [];

      QuerySnapshot studentSnapshot = await _firestore
          .collection('Users')
          .where('busId', isEqualTo: busId)
          .where('role', isEqualTo: 'student')
          .get();

      return studentSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.get('name') ?? 'ไม่ทราบชื่อ',
          'status': 'waiting', // Default status
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting students on bus: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Driver view
    if (_userRole == 'driver') {
      return _buildDriverView();
    }
    // Parent view
    else if (_userRole == 'parent') {
      return _buildParentView();
    }
    // Student view
    else if (_userRole == 'student') {
      return _buildStudentView();
    }
    // Default view for other roles
    else {
      return _buildDefaultView();
    }
  }

  // Driver view with interactive controls
  Widget _buildDriverView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามรถนักเรียน - พนักงานขับรถ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bus status indicators
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'สถานะรถ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/school-bus.gif',
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'คุณเป็นพนักงานขับรถ',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Action buttons for bus tracking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'กิจกรรมรถรับส่ง',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bus departure to school button
                      ElevatedButton.icon(
                        onPressed: _handleBusDepartureToSchool,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.directions_bus),
                        label: const Text('ออกเดินทาง - รับนักเรียน'),
                      ),
                      const SizedBox(height: 10),
                      
                      // Show list of students to pick up
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getStudentsOnBus(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('ไม่มีนักเรียนในรถคันนี้');
                          }

                          List<Map<String, dynamic>> students = snapshot.data!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'รายชื่อนักเรียนที่ต้องไปรับ:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...students.map((student) => 
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(student['name']),
                                        ElevatedButton(
                                          onPressed: () => _handleStudentBusPickup(student['id'], student['name']),
                                          child: const Text('รับขึ้นรถ'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ).toList(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      
                      // Bus arrival at school button
                      ElevatedButton.icon(
                        onPressed: _handleBusArrivalAtSchool,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.school),
                        label: const Text('ถึงโรงเรียน'),
                      ),
                      const SizedBox(height: 20),
                      
                      // Home-bound actions
                      const Divider(),
                      const Text(
                        'เดินทางกลับบ้าน',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bus departure to home button
                      ElevatedButton.icon(
                        onPressed: _handleBusDepartureToHome,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.home),
                        label: const Text('ออกเดินทาง - กลับบ้าน'),
                      ),
                      const SizedBox(height: 10),
                      
                      // Show list of students to drop off
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getStudentsOnBus(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('ไม่มีนักเรียนในรถคันนี้');
                          }

                          List<Map<String, dynamic>> students = snapshot.data!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'รายชื่อนักเรียนที่ต้องส่ง:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...students.map((student) => 
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(student['name']),
                                        ElevatedButton(
                                          onPressed: () => _handleStudentBusDropoffAtHome(student['id'], student['name']),
                                          child: const Text('ส่งถึงบ้าน'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Parent view - read-only
  Widget _buildParentView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามรถนักเรียน - ผู้ปกครอง'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getParentBusTrackingStream(),
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
                  Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลรถรับส่งในขณะนี้',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final busTrackingDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: busTrackingDocs.length,
            itemBuilder: (context, index) {
              final trackingData = busTrackingDocs[index].data() as Map<String, dynamic>;
              return _buildBusTrackingCard(trackingData);
            },
          );
        },
      ),
    );
  }

  // Student view - read-only
  Widget _buildStudentView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามรถนักเรียน - นักเรียน'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getStudentBusTrackingStream(),
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
                  Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลรถรับส่งของคุณ',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final busTrackingDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: busTrackingDocs.length,
            itemBuilder: (context, index) {
              final trackingData = busTrackingDocs[index].data() as Map<String, dynamic>;
              return _buildBusTrackingCard(trackingData);
            },
          );
        },
      ),
    );
  }

  // Stream for parent to get bus tracking notifications for their children
  Stream<QuerySnapshot> _getParentBusTrackingStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Get the user document to find their children
    return _firestore
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      List<dynamic>? children = userDoc.get('children') as List<dynamic>?;
      if (children == null || children.isEmpty) {
        // Return empty query if no children
        return await _firestore
            .collection('Notifications')
            .where('type', isEqualTo: 'bus_tracking')
            .where('recipientId', isEqualTo: user.uid) // Only notifications for this parent
            .orderBy('timestamp', descending: true)
            .limit(10) // Limit to recent notifications
            .get();
      }

      // Get bus tracking notifications related to their children
      return await _firestore
          .collection('Notifications')
          .where('type', isEqualTo: 'bus_tracking')
          .where('recipientId', isEqualTo: user.uid) // Notifications for this parent
          .orderBy('timestamp', descending: true)
          .get();
    });
  }

  // Stream for student to get their own bus tracking notifications
  Stream<QuerySnapshot> _getStudentBusTrackingStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('Notifications')
        .where('type', isEqualTo: 'bus_tracking')
        .where('recipientId', isEqualTo: user.uid) // Notifications for this student
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Build a card for bus tracking information
  Widget _buildBusTrackingCard(Map<String, dynamic> trackingData) {
    String title = trackingData['title'] ?? 'แจ้งเตือนรถรับส่ง';
    String body = trackingData['body'] ?? 'ไม่มีรายละเอียด';
    String senderName = trackingData['senderName'] ?? 'ระบบ';
    DateTime timestamp = (trackingData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    Map<String, dynamic>? payload = trackingData['payload'] as Map<String, dynamic>?;

    // Determine bus status icon and color
    IconData icon = Icons.directions_bus;
    Color iconColor = Colors.blue;
    String statusText = 'กำลังเดินทาง';

    if (payload != null) {
      String action = payload['action'] ?? '';
      switch (action) {
        case 'departure_to_school':
          icon = Icons.directions_bus;
          iconColor = Colors.blue;
          statusText = 'กำลังไปรับนักเรียน';
          break;
        case 'student_pickup':
          icon = Icons.person_add_alt_1;
          iconColor = Colors.green;
          statusText = 'รับนักเรียนขึ้นรถ';
          break;
        case 'arrival_at_school':
          icon = Icons.school;
          iconColor = Colors.green;
          statusText = 'ถึงโรงเรียน';
          break;
        case 'departure_to_home':
          icon = Icons.home;
          iconColor = Colors.orange;
          statusText = 'กำลังกลับบ้าน';
          break;
        case 'student_dropoff':
          icon = Icons.person_remove_alt_1;
          iconColor = Colors.red;
          statusText = 'ส่งนักเรียนถึงบ้าน';
          break;
      }
    }

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จาก: $senderName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Default view for other roles
  Widget _buildDefaultView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามรถนักเรียน'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('ไม่มีสิทธิ์ในการเข้าถึงหน้านี้'),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
