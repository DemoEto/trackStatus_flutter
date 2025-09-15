class Attendance {
  final String attendanceId;
  final String stdId;
  final String subId;
  final String type;
  final String status;
  final String timestamp;
  
  Attendance({
    required this.attendanceId, 
    required this.stdId, 
    required this.subId, 
    required this.type,
    required this.status,
    required this.timestamp});
}

// Collection: Attendance
// DocumentId = ${studentId}_${subjectIdOrType}_${date}
// Fields:
// studentId
// subjectId (nullable ถ้าเป็น school_in/school_out)
// type (school_in, class_in, school_out)
// status ("มา", "ลา", "ขาด")
// timestamp