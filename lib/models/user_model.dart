class StudentData {
  final String name;
  final String role;
  final String busId;
  final String stdId;

  StudentData({
    required this.name,
    required this.role,
    required this.busId,
    required this.stdId,
  });

  // แปลงเป็น Map สำหรับบันทึก Firestore
  Map<String, dynamic> toMap() {
    return {
      name: name,
      role: role,
      busId: busId,
      stdId: stdId,
    };
  }

  // โหลดจาก Firestore document
  factory StudentData.fromMap(Map<String, dynamic> map) {
    return StudentData(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      busId: map['busId'] ?? '',
      stdId: map['stdId'] ?? 'student',
    );
  }
}

class TeacherData {
  final String name;
  final String role;
  final String sub_ID;

  TeacherData({
    required this.name,
    required this.role,
    required this.sub_ID,
  });

  // แปลงเป็น Map สำหรับบันทึก Firestore
  Map<String, dynamic> toMap() {
    return {
      name: name,
      role: role,
      sub_ID: sub_ID,
    };
  }

  // โหลดจาก Firestore document
  factory TeacherData.fromMap(Map<String, dynamic> map) {
    return TeacherData(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      sub_ID: map['sub_ID'] ?? '',
    );
  }
}
