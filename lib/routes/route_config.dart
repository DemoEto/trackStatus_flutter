import 'package:go_router/go_router.dart';
import 'package:trackstatus_flutter/pages/academic_profile_page.dart';
import 'package:trackstatus_flutter/pages/service_page.dart';

import 'app_route.dart';

import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../services/auth_service.dart';
import '../pages/attend_history_page.dart';
import '../pages/qr_checkin_page.dart';

final GoRouter router = GoRouter(
  refreshListenable: authService,
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final loggedIn = authService.currentUser != null;
    final goingToLogin = state.uri.path == AppRoutes.login;

    if (!loggedIn && !goingToLogin) return AppRoutes.login;
    if (loggedIn && goingToLogin) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
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
      builder: (context, state) => const ServicePage(),
    ),
    GoRoute(
      path: AppRoutes.qrCheckin,
      builder: (context, state) => const QrCheckinPage(),
    ),
    GoRoute(
      path: AppRoutes.academicProfile,
      builder: (context, state) => const AcademicProfilePage(),
    ),
  ],
);
