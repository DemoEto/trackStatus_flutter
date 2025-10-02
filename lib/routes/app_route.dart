class AppRoutes {
  // Authentication Routes
  static const String login = '/login';
  
  // Main Navigation Routes
  static const String home = '/home';
  static const String services = '/services';
  static const String notifications = '/notifications';
  
  // Attendance Routes
  static const String attendanceHistory = '/attendance-history';
  static const String qrCheckin = '/qr-checkin';
  static const String qrScan = '/qr-scanner';
  static const String qrCheckinScan = '/qr-checkin-scan';
  
  // Academic Routes
  static const String academicProfile = '/academic-profile';
  static const String homework = '/homework';
  static const String homeworkAssignment = '/homework/assignment';
  
  // Transportation Routes
  static const String followVehicle = '/follow-vehicle';
  static const String vehicle = '/vehicle';
  
  // Admin Management Routes
  static const String adminManagement = '/admin/management';
  static const String usersManagement = '/admin/users';
  static const String addUser = '/admin/users/add';
  static const String editUser = '/admin/users/edit';
  static const String attendanceManagement = '/admin/attendance';
  static const String addAttendance = '/admin/attendance/add';
  static const String editAttendance = '/admin/attendance/edit';
  static const String notificationManagement = '/admin/notifications';
}
