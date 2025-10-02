import 'package:go_router/go_router.dart';
import 'package:trackstatus_flutter/routes/app_route.dart';
import 'package:trackstatus_flutter/pages/admin/add_user_page.dart';
import 'package:trackstatus_flutter/pages/admin/add_attendance_page.dart';
import 'package:trackstatus_flutter/pages/admin/edit_user_page.dart';
import 'package:trackstatus_flutter/pages/admin/edit_attendance_page.dart';
import 'package:trackstatus_flutter/pages/admin/attendance_management_page.dart';
import 'package:trackstatus_flutter/pages/admin/users_management_page.dart';
import 'package:trackstatus_flutter/pages/admin/notification_management_page.dart';
import 'package:trackstatus_flutter/pages/follow_bus/follow_vehicle_page.dart';
import 'package:trackstatus_flutter/pages/qr_code/qr_scanner_page.dart';

import '../pages/services/academic_profile_page.dart';
import '../pages/announcement/notification_history_page.dart';
import '../pages/services/service_page.dart';
import '../pages/home/home_page.dart';
import '../pages/login/login_page.dart';
import '../pages/scan_history/attendance_history_page.dart';
import '../pages/qr_code/qr_checkin_page.dart';
import 'package:trackstatus_flutter/pages/my_vehicle/vehicle_page.dart';
import '../pages/admin/admin_management_page.dart';
import '../pages/home_work/homework_submission_page.dart';
import '../pages/home_work/homework_assignment_page.dart';
import '../services/auth_service.dart';

final GoRouter router = GoRouter(
  refreshListenable: authService,
  initialLocation: AppRoutes.login,
  redirect: (context, state) async {
    final loggedIn = authService.currentUser != null;
    final goingToLogin = state.uri.path == AppRoutes.login;

    if (!loggedIn && !goingToLogin) return AppRoutes.login;
    if (context.mounted && loggedIn && goingToLogin) {
      // Get user role and redirect accordingly
      // final user = authService.currentUser;
      // if (user != null) {
      //   String? userRole = await authService.getUserRole(user.uid);
        
      //   switch (userRole) {
      //     case 'admin':
      //       return AppRoutes.adminManagement;
      //     case 'teacher':
      //       return AppRoutes.qrCheckin; // หรือหน้าที่เหมาะสมสำหรับครู
      //     case 'student':
      //       return AppRoutes.home; // หรือหน้าที่เหมาะสมสำหรับนักเรียน
      //     case 'parent':
      //       return AppRoutes.attendHistory; // หรือหน้าที่เหมาะสมสำหรับผู้ปกครอง
      //     case 'driver':
      //       return AppRoutes.followVehicle; // หรือหน้าที่เหมาะสมสำหรับพนักงานขับรถ
      //     default:
      //       return AppRoutes.home; // ค่าเริ่มต้น
      //   }
      // }
      return AppRoutes.home;
    }

    // ตรวจสอบบทบาทเพื่อจำกัดการเข้าถึง
    if (loggedIn) {
      final user = authService.currentUser;
      if (user != null) {
        String? userRole = await authService.getUserRole(user.uid);
        
        // จำกัดการเข้าถึงหน้า admin สำหรับ non-admin
        if (state.fullPath?.contains('/admin') ?? false && userRole != 'admin') {
          return AppRoutes.home;
        }
        
        // จำกัดการเข้าถึงหน้าเฉพาะสำหรับบทบาทอื่นๆ ได้ตามต้องการ
        if ((state.fullPath?.contains('/attendanceManagement') ?? false) && 
            userRole != 'admin' && userRole != 'teacher') {
          return AppRoutes.home;
        }
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.attendanceHistory, //'/attendance-history'
      builder: (context, state) => const AttendanceHistoryPage(),
    ),
    GoRoute(
      path: AppRoutes.services,
      builder: (context, state) => const ServicesPage(),
    ),
    GoRoute(
      path: AppRoutes.qrCheckin,
      builder: (context, state) => const QrCheckinPage(fromQrScan: false,subId: "",date: "",),
    ),
    // GoRoute(
    //   path: AppRoutes.qrCheckinScan,
    //   builder: (context, state) => const QrCheckinPage(fromQrScan: true),
    // ),
    GoRoute(
      path: '${AppRoutes.qrCheckinScan}/:subId/:date/:teacherId',
      name: AppRoutes.qrCheckinScan,
      builder: (context, state) {
        final subId = state.pathParameters['subId']!;
        final date = state.pathParameters['date']!;
        final teacherId = state.pathParameters['teacherId']!;
        return QrCheckinPage(
          fromQrScan: true,
          subId: subId,
          date: date,
          teacherId: teacherId,
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.qrCheckinScan}/:subId/:date/:teacherId/:allowLateScans',
      name: 'qrCheckinScanWithLate',
      builder: (context, state) {
        final subId = state.pathParameters['subId']!;
        final date = state.pathParameters['date']!;
        final teacherId = state.pathParameters['teacherId']!;
        final allowLateScans = state.pathParameters['allowLateScans'] == 'true';
        return QrCheckinPage(
          fromQrScan: true,
          subId: subId,
          date: date,
          teacherId: teacherId,
          allowLateScans: allowLateScans,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.academicProfile,
      builder: (context, state) => const AcademicProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.followVehicle,
      builder: (context, state) => const FollowVehiclePage(),
    ),
    GoRoute(
      path: AppRoutes.vehicle,
      builder: (context, state) => const VehiclePage(),
    ),
    GoRoute(
      path: AppRoutes.qrScan,
      builder: (context, state) => const QrScannerPage(),
    ),
    GoRoute(
      path: AppRoutes.adminManagement,
      builder: (context, state) => const AdminManagementPage(),
    ),

    GoRoute(
      path: AppRoutes.usersManagement,
      builder: (context, state) => const UsersManagementPage(),
    ),
    GoRoute(
      path: AppRoutes.addUser,
      builder: (context, state) => const AddUserPage(),
    ),
    GoRoute(
      path: '${AppRoutes.editUser}/:uid',
      name: AppRoutes.editUser,
      builder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return EditUserPage(uid: uid,);
      },
    ),

    GoRoute(
      path: AppRoutes.attendanceManagement,
      builder: (context, state) => const AttendanceManagementPage(),
    ),
    GoRoute(
      path: AppRoutes.addAttendance,
      builder: (context, state) => const AddattendancePage(),
    ),
    GoRoute(
      path: '${AppRoutes.editAttendance}/:attendanceId',
      name: AppRoutes.editAttendance,
      builder: (context, state) {
        final attendanceId = state.pathParameters['attendanceId']!;
        return EditAttendancePage(attendanceId: attendanceId,);
      },
    ),
    GoRoute(
      path: AppRoutes.notificationManagement,
      builder: (context, state) => const NotificationManagementPage(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationHistoryPage(),
    ),
    GoRoute(
      path: AppRoutes.homework,
      builder: (context, state) => const HomeworkSubmissionPage(), // For students
    ),
    GoRoute(
      path: '${AppRoutes.homework}/assignment',
      name: 'homeworkAssignment',
      builder: (context, state) => const HomeworkAssignmentPage(), // For teachers
    ),
  ],
);
