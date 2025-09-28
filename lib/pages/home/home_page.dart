import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../routes/app_route.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final WebViewController webViewController;

  final userService = UserService();
  String? _role;

  Future<void> signOut() async {
    await AuthService().signOut();
  }

  @override
  void initState() {
    super.initState();
    // สร้าง WebViewController สำหรับแสดงเว็บไซต์
    PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params =
          WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params =
          AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    }

    webViewController = WebViewController.fromPlatformCreationParams(params);
    webViewController.loadRequest(Uri.parse('https://www.rmutl.ac.th/'));

    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Get the role with the stream (real-time updates)
      userService.streamUser(uid).listen((student) {
        if (student != null && mounted) {
          setState(() {
            _role = student.role; // ✅ อัพเดต role
          });
        }
      });
    }
  }

  Widget _getBody() {
    return Column(
      children: [
        Expanded(child: WebViewWidget(controller: webViewController)),
      ],
    );
  }

  

  Widget _buttomNavigation() {
    // Determine which destinations to show based on role
    List<NavigationDestination> destinations = [
      const NavigationDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Badge(child: Icon(Icons.notifications_sharp)),
        label: 'Notifications',
      ),
    ];
    List<String> navigationActions = [
      '', // Home action (handled separately to go to root)
      '/notifications', // Notifications
    ];

    // Add QR Scan for students only
    if (_role != null && _role == 'student') {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner), 
        label: 'Scan',
      ));
      navigationActions.add(AppRoutes.qrScan);
    }
    
    // Add QR Check-in for teachers only
    if (_role != null && _role == 'teacher') {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.qr_code), 
        label: 'QR Check-in',
      ));
      navigationActions.add(AppRoutes.qrCheckin);
    }

    // Add Follow Vehicle for drivers only
    if (_role != null && _role == 'driver') {
      destinations.add(const NavigationDestination(
        icon: FaIcon(FontAwesomeIcons.carOn),
        label: 'Detect car',
      ));
      navigationActions.add(AppRoutes.followVehicle);
    }

    // Add Admin Management for admins only
    if (_role != null && _role == 'admin') {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.admin_panel_settings), 
        label: 'Admin',
      ));
      navigationActions.add(AppRoutes.adminManagement);
    }

    // Add scan history for all users
    destinations.add(const NavigationDestination(
      icon: const Icon(Icons.qr_code), 
      label: 'History',
    ));
    navigationActions.add(AppRoutes.attendHistory);

    // Add service/profile page for all users
    destinations.add(const NavigationDestination(
      icon: Icon(Icons.person), 
      label: 'Service',
    ));
    navigationActions.add(AppRoutes.service);

    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        if (index >= 0 && index < navigationActions.length) {
          String action = navigationActions[index];
          
          if (index == 0) {
            // If user taps on Home when already on home page, do nothing
            // If user taps on Home when on another page, go back to home stack
            // Using go instead of push to replace the current route with home
            if (ModalRoute.of(context)?.settings.name != '/') {
              context.go('/');  // Go to the initial home route
            } else {
              // If already on home, we might want to scroll to top or just stay
              // For now, we'll just update the selected index
            }
          } else if (action.isNotEmpty) {
            // Navigate to the selected destination
            context.push(action);
          }
        }
        
        // Update selected index
        setState(() {
          _selectedIndex = index;
        });
      },
      indicatorColor: const Color.fromARGB(255, 197, 211, 232),
      destinations: destinations,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut(); // logout
              if (mounted) {
                context.go(AppRoutes.login); // Use go to navigate to login
              }
            },
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: _buttomNavigation(),
    );
  }
}
