import 'package:go_router/go_router.dart';
import 'package:trackstatus_flutter/pages/admin/addAttendance_page.dart';
import 'package:trackstatus_flutter/pages/admin/addUser_page.dart';
import 'package:trackstatus_flutter/pages/admin/attendance_manament_page.dart';
import 'package:trackstatus_flutter/pages/admin/editUser_page.dart';
import 'package:trackstatus_flutter/pages/admin/users_manament_page.dart';
import 'package:trackstatus_flutter/pages/follow_vehicle_page.dart';
import 'package:trackstatus_flutter/pages/qr_scanner_page.dart';
import 'app_route.dart';

import '../pages/academic_profile_page.dart';
import '../pages/service_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/attend_history_page.dart';
import '../pages/qr_checkin_page.dart';
import '../pages/vehicle_page.dart';
import '../pages/admin_management_page.dart';
import '../services/auth_service.dart';

final GoRouter router = GoRouter(
  refreshListenable: authService,
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final loggedIn = authService.currentUser != null;
    final goingToLogin = state.uri.path == AppRoutes.login;

    if (!loggedIn && !goingToLogin) return AppRoutes.login;
    if (context.mounted && loggedIn && goingToLogin) return AppRoutes.home;
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
      path: AppRoutes.attendHistory, //'/attendHistory'
      builder: (context, state) => const AttendHistoryPage(),
    ),
    GoRoute(
      path: AppRoutes.service,
      builder: (context, state) => const ServicesPage(),
    ),
    GoRoute(
      path: AppRoutes.qrCheckin,
      builder: (context, state) => const QrCheckinPage(fromQrScan: false,subId: "",),
    ),
    // GoRoute(
    //   path: AppRoutes.qrCheckinScan,
    //   builder: (context, state) => const QrCheckinPage(fromQrScan: true),
    // ),
    GoRoute(
      path: AppRoutes.qrCheckinScan + '/:subId',
      name: AppRoutes.qrCheckinScan,
      builder: (context, state) {
        final subId = state.pathParameters['subId']!;
        return QrCheckinPage(fromQrScan: true,subId: subId);
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
      path: AppRoutes.editUser + '/:uid',
      name: AppRoutes.editUser,
      builder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return EditUserPage(uid: uid,);
      },
    ),

    GoRoute(
      path: AppRoutes.attandenceManagement,
      builder: (context, state) => const AttendanceManamentPage(),
    ),
    GoRoute(
      path: AppRoutes.addAttendance,
      builder: (context, state) => const AddattendancePage(),
    ),
    GoRoute(
      path: AppRoutes.editAttendance + '/:uid',
      name: AppRoutes.editAttendance,
      builder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return EditUserPage(uid: uid,);
      },
    ),
  ],
);
