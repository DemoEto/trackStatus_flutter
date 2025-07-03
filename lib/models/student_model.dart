class Student {
  final String id;
  final String name;
  String? status; // สามารถเป็น null ได้ถ้ายังไม่ได้เลือก

  Student({required this.id, required this.name, this.status});
}