import 'package:go_router/go_router.dart';
import 'package:trackstatus_flutter/pages/feature_AdminManagement/addAttendance_page.dart';
import 'package:trackstatus_flutter/pages/feature_AdminManagement/addUser_page.dart';
import 'package:trackstatus_flutter/pages/feature_AdminManagement/attendance_manament_page.dart';
import 'package:trackstatus_flutter/pages/feature_AdminManagement/editUser_page.dart';
import 'package:trackstatus_flutter/pages/feature_AdminManagement/users_manament_page.dart';
import 'package:trackstatus_flutter/pages/feature_followBuses/follow_vehicle_page.dart';
import 'package:trackstatus_flutter/pages/feature_QRscan/qr_scanner_page.dart';
import 'app_route.dart';

import '../pages/feautre_Services/academic_profile_page.dart';
import '../pages/feautre_Services/service_page.dart';
import '../pages/feature_HomePage/home_page.dart';
import '../pages/feature_Login/login_page.dart';
import '../pages/feature_ScanHistories/attend_history_page.dart';
import '../pages/feature_QRscan/qr_checkin_page.dart';
import '../pages/feature_AddMyVehicle/vehicle_page.dart';
import '../pages/feature_AdminManagement/admin_management_page.dart';
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
      builder: (context, state) => const QrCheckinPage(fromQrScan: false,subId: "",date: "",),
    ),
    // GoRoute(
    //   path: AppRoutes.qrCheckinScan,
    //   builder: (context, state) => const QrCheckinPage(fromQrScan: true),
    // ),
    GoRoute(
      path: AppRoutes.qrCheckinScan + '/:subId/:date/:teacherId',
      name: AppRoutes.qrCheckinScan,
      builder: (context, state) {
        final subId = state.pathParameters['subId']!;
        final date = state.pathParameters['date']!;
        return QrCheckinPage(fromQrScan: true,subId: subId,date: date);
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
