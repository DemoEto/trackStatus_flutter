# FCM Notification Requirements - Todo List

## Overall FCM Implementation Strategy

### Client-side vs. Server-side Implementation
- [ ] **CRITICAL**: Client-side FCM implementation is **NOT recommended** for sending notifications to multiple users
- [ ] Server-side implementation required for production apps
- [ ] Firebase Cloud Functions recommended for server-side FCM
- [ ] Backend service needed for sending notifications to parents when students scan QR codes
- [ ] Backend service needed for sending notifications for bus status updates

---

## Feature 1: QR Scan Notifications

### 1.1 School Arrival Notification (นักเรียนแสกน qr มาโรงเรียน)
- [ ] **Backend Function**: Trigger when student scans school arrival QR
- [ ] **Notification Type**: "school_arrival"
- [ ] **Target**: Parent(s) of the student
- [ ] **Content**: "ลูกของคุณ [ชื่อนักเรียน] ได้เดินทางมาถึงโรงเรียนแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**: 
  - studentId
  - studentName  
  - location: "school_arrival"
  - timestamp
  - type: "arrival_notification"

### 1.2 Subject Class Check-in Notification (นักเรียนแสกน qr เข้าห้องเรียนแต่ละวิชา)
- [ ] **Backend Function**: Trigger when student scans classroom QR
- [ ] **Notification Type**: "class_checkin"
- [ ] **Target**: Parent(s) of the student
- [ ] **Content**: "ลูกของคุณ [ชื่อนักเรียน] ได้เข้าเรียนวิชา [ชื่อวิชา] แล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - studentId
  - studentName
  - subjectId
  - subjectName
  - location: "classroom"
  - timestamp
  - type: "class_checkin"

### 1.3 School Departure Notification (นักเรียนแสกน qr ออกโรงเรียน)
- [ ] **Backend Function**: Trigger when student scans school departure QR
- [ ] **Notification Type**: "school_departure"
- [ ] **Target**: Parent(s) of the student
- [ ] **Content**: "ลูกของคุณ [ชื่อนักเรียน] ได้ออกจากโรงเรียนแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - studentId
  - studentName
  - location: "school_departure"
  - timestamp
  - type: "departure_notification"

---

## Feature 2: Bus Tracking Notifications

### 2.1 Bus Departure - School Bound (ส่งนักเรียนไป รร. - คนขับรถนักเรียนกดปุ่มออกเดินทาง)
- [ ] **Backend Function**: Trigger when driver starts school-bound trip
- [ ] **Notification Type**: "bus_departure_school"
- [ ] **Target**: All parents of students on this bus route
- [ ] **Content**: "รถบัสกำลังเดินทางออกจากต้นทาง มุ่งหน้าสู่โรงเรียน วันที่ [เวลา]"
- [ ] **Data Payload**:
  - busId
  - routeName
  - driverId
  - departureTime
  - direction: "to_school"
  - type: "bus_departure"

### 2.2 Student Pick-up Notification (คนขับรถนักเรียนกดปุ่มรับนักเรียน)
- [ ] **Backend Function**: Trigger when driver marks student pickup
- [ ] **Notification Type**: "student_pickup"
- [ ] **Target**: Parent of the specific student
- [ ] **Content**: "[ชื่อนักเรียน] ได้ขึ้นรถบัสเรียบร้อยแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - studentId
  - studentName
  - busId
  - pickupTime
  - location
  - type: "student_pickup"

### 2.3 Student School Arrival Notification (คนขับรถนักเรียนกดปุ่มส่งนักเรียนที่โรงเรียน)
- [ ] **Backend Function**: Trigger when driver marks student arrival at school
- [ ] **Notification Type**: "student_arrived_school"
- [ ] **Target**: All parents of students who were on this bus
- [ ] **Content**: "รถบัสได้ส่งนักเรียนทุกคนถึงโรงเรียนเรียบร้อยแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - busId
  - arrivalTime
  - location: "school"
  - type: "bus_arrived_school"

### 2.4 Bus Departure - Home Bound (รับนักเรียนกลับบ้าน - คนขับรถนักเรียนกดปุ่มออกเดินทาง)
- [ ] **Backend Function**: Trigger when driver starts home-bound trip
- [ ] **Notification Type**: "bus_departure_home"
- [ ] **Target**: All parents of students on this bus route
- [ ] **Content**: "รถบัสกำลังเดินทางออกจากโรงเรียน มุ่งหน้าสู่จุดหมายปลายทาง วันที่ [เวลา]"
- [ ] **Data Payload**:
  - busId
  - routeName
  - driverId
  - departureTime
  - direction: "to_home"
  - type: "bus_departure"

### 2.5 Student School Pick-up Notification (คนขับรถนักเรียนกดปุ่มรับนักเรียนที่โรงเรียน)
- [ ] **Backend Function**: Trigger when driver marks student pickup from school
- [ ] **Notification Type**: "student_pickup_school"
- [ ] **Target**: All parents of students on this bus
- [ ] **Content**: "รถบัสได้รับนักเรียนจากโรงเรียนเรียบร้อยแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - busId
  - departureTime
  - location: "school"
  - type: "bus_pickup_student"

### 2.6 Student Home Arrival Notification (คนขับรถนักเรียนกดปุ่มส่งนักเรียนเมื่อส่งนักเรียนคนนั้นถึงบ้าน)
- [ ] **Backend Function**: Trigger when driver marks student drop-off at home
- [ ] **Notification Type**: "student_arrived_home"
- [ ] **Target**: Parent of the specific student
- [ ] **Content**: "[ชื่อนักเรียน] ได้ถึงบ้านเรียบร้อยแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - studentId
  - studentName
  - busId
  - arrivalTime
  - location: "home"
  - type: "student_arrived_home"

---

## Backend Implementation Requirements

### Firebase Cloud Functions Setup
- [ ] Create Firebase project with Cloud Functions enabled
- [ ] Set up HTTPS triggers for each notification type
- [ ] Implement Firebase Admin SDK for FCM messaging
- [ ] Connect to Firestore to retrieve parent FCM tokens
- [ ] Implement security rules and validation

### Firestore Database Structure
- [ ] Update Users collection to store parent-child relationships
- [ ] Store FCM tokens for each user
- [ ] Create Bus routes and assignments structure
- [ ] Student-bus relationship tracking
- [ ] Trip/Route history tracking

### Client-side Functions to Implement
- [ ] Function to send trip status updates to backend
- [ ] Function to send QR scan events to backend
- [ ] Function to retrieve parent-child relationships
- [ ] Proper error handling for notification failures

---

## Client-side Functions (Temporary Implementation)

While the server-side solution is being developed, you can implement these client-side functions to prepare for the full implementation:

### 1. QR Scan Event Handler
```dart
// Temporary placeholder - to be replaced with backend call
Future<void> handleQRScanEvent({
  required String studentId,
  required String scanType, // 'school_in', 'class_in', 'school_out'
  required String location,
  required String subjectId, // optional
}) async {
  // Call backend function instead of sending notifications directly
  await sendQRScanEventToBackend(
    studentId: studentId,
    scanType: scanType,
    location: location,
    subjectId: subjectId,
  );
}
```

### 2. Bus Status Update Handler
```dart
// Temporary placeholder - to be replaced with backend call
Future<void> handleBusStatusUpdate({
  required String busId,
  required String driverId,
  required String status, // 'departure', 'pickup', 'arrival_school', 'arrival_home'
  String? studentId, // for individual notifications
  List<String>? studentList, // for group notifications
}) async {
  // Call backend function instead of sending notifications directly
  await sendBusStatusToBackend(
    busId: busId,
    driverId: driverId,
    status: status,
    studentId: studentId,
    studentList: studentList,
  );
}
```

### 3. Parent Lookup Function
```dart
Future<List<String>> getParentsForStudent(String studentId) async {
  // Query Firestore to find all parents associated with this student
  // Return list of parent FCM tokens
  // This will be used by backend functions, not client-side
}
```

---

## Security Considerations

- [ ] Implement proper authentication for driver status updates
- [ ] Validate student-parent relationships
- [ ] Rate limiting for notification sending
- [ ] Protect against notification spamming
- [ ] Secure FCM token storage and retrieval

---

## Feature 3: Homework Notifications

### 3.1 Teacher Assigns Homework
- [ ] **Backend Function**: Trigger when teacher assigns homework
- [ ] **Notification Type**: "homework_assigned"
- [ ] **Target**: Student and parent of the student
- [ ] **Content**: "ครู [ชื่อครู] ได้มอบหมายการบ้านวิชา [ชื่อวิชา] ชื่องาน [ชื่องาน] กำหนดส่งวันที่ [วันที่ส่ง] วันที่ [เวลา]"
- [ ] **Data Payload**:
  - assignmentId
  - teacherId
  - teacherName
  - subjectId
  - subjectName
  - assignmentTitle
  - assignmentDescription
  - dueDate
  - assignedStudents: List of student IDs
  - type: "homework_assigned"

### 3.2 Student Submits Homework
- [ ] **Backend Function**: Trigger when student submits homework
- [ ] **Notification Type**: "homework_submitted"
- [ ] **Target**: Teacher who assigned the homework
- [ ] **Content**: "นักเรียน [ชื่อนักเรียน] ได้ส่งการบ้าน [ชื่องาน] เรียบร้อยแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - assignmentId
  - studentId
  - studentName
  - teacherId
  - assignmentTitle
  - submissionTime
  - type: "homework_submitted"

### 3.3 Assignment Deadline Reminder
- [ ] **Backend Function**: Scheduled function to check upcoming deadlines
- [ ] **Notification Type**: "deadline_reminder"
- [ ] **Target**: Students who haven't submitted the assignment
- [ ] **Content**: "เตือน! การบ้าน [ชื่องาน] วิชา [ชื่อวิชา] มีกำหนดส่งในอีก [จำนวนวัน] วัน วันที่ [เวลา]"
- [ ] **Data Payload**:
  - assignmentId
  - studentId
  - assignmentTitle
  - subjectName
  - dueDate
  - daysRemaining
  - type: "deadline_reminder"

### 3.4 Assignment Overdue Notification
- [ ] **Backend Function**: Scheduled function to check overdue assignments  
- [ ] **Notification Type**: "assignment_overdue"
- [ ] **Target**: Students who haven't submitted the assignment and their parents
- [ ] **Content**: "แจ้งเตือน! การบ้าน [ชื่องาน] วิชา [ชื่อวิชา] ค้างส่งเกินกำหนดแล้ว วันที่ [เวลา]"
- [ ] **Data Payload**:
  - assignmentId
  - studentId
  - studentName
  - assignmentTitle
  - subjectName
  - dueDate
  - type: "assignment_overdue"

---

## Backend Implementation Requirements

- [ ] Create assignments collection in Firestore
- [ ] Create submission tracking system
- [ ] Implement scheduled functions for deadline reminders
- [ ] Connect to student-teacher-subject relationships
- [ ] Create assignment notification preferences per user

## Testing Plan

- [ ] Test QR scan notification flow
- [ ] Test bus tracking notification flow
- [ ] Test homework assignment notification flow
- [ ] Test homework submission notification flow
- [ ] Test deadline reminder notification flow
- [ ] Test parent notification delivery
- [ ] Test multiple parent scenarios
- [ ] Test offline scenarios
- [ ] Test notification payload handling on client
- [ ] Test scheduled reminder functions