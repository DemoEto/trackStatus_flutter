class Attendance {
  final String attendanceId;
  final String stdId;
  final String? subId;  //  nullable ถ้าเป็น school_in/school_out
  final String type;     // school_in, class_in, school_out
  final String status;   // "มา", "ลากิจ", "ลาป่วย", "ขาด"
  final String timestamp;
  
  Attendance({
    required this.attendanceId, 
    required this.stdId, 
    this.subId, 
    required this.type,
    required this.status,
    required this.timestamp});
  
  // แปลงจาก Map ไปเป็น Attendance object
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      attendanceId: map['attendanceId'] ?? map['id'] ?? '',
      stdId: map['studentId'] ?? map['stdId'] ?? '',
      subId: map['subId'],
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }

  // แปลงจาก Attendance object ไปเป็น Map
  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'studentId': stdId,
      'subId': subId,
      'type': type,
      'status': status,
      'timestamp': timestamp,
    };
  }
}

// Collection: Attendance
// DocumentId = ${studentId}_${subjectIdOrType}_${date}
// Fields:
// studentId
// subjectId (nullable ถ้าเป็น school_in/school_out)
// type (school_in, class_in, school_out)
// status ("มา", "ลากิจ", "ลาป่วย", "ขาด")
// timestamp