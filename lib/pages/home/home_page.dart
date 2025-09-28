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
import '../../models/user_model.dart';

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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      userService.streamUser(uid).listen((student) {
        if (student != null) {
          if (mounted) {
            setState(() {
              _role = student.role; // ✅ อัพเดต role
            });
          }
        }
      });
    }
  }

  Widget _userInfoBar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text("ไม่พบผู้ใช้");

    return StreamBuilder<StudentData?>(
      stream: userService.streamUser(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(user.name),
            Text(user.role),
            ElevatedButton(onPressed: signOut, child: Text('Sign Out')),
          ],
        );
      },
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: _userInfoBar()),
        Expanded(child: WebViewWidget(controller: webViewController)),
      ],
    );
  }

  Widget _drawermenu() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Setting',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Scan History'),
            onTap: () {
              context.push(AppRoutes.attendHistory);
            },
          ),
          if (_role == 'admin') 
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Management'),
              onTap: () {
                context.push(AppRoutes.adminManagement);
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await AuthService().signOut(); // logout
              if (mounted) {
                context.go(AppRoutes.login); // Use go to navigate to login
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buttomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index == 1) { // Notifications
          context.push('/notifications');
        } else if (index == 2) { // QR Scan
          if (_role == 'student') {
            context.push(AppRoutes.qrScan);
          } else {
            ScaffoldMessenger.of(context,).showSnackBar(SnackBar(
              content: Text('คุณไม่ใช่นักเรียนจึงไม่สามารถแสกนได้')
            ));
            return; // Don't change the selected index
          }
        } else if (index == 3) { // Follow Vehicle (Detect car)
          context.push(AppRoutes.followVehicle);
        } else if (index == 4) { // Service
          context.push(AppRoutes.service);
        }
        
        // Only update selected index if it's a valid navigation
        setState(() {
          _selectedIndex = index;
        });
      },
      indicatorColor: const Color.fromARGB(255, 197, 211, 232),
      destinations: [
        const NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Badge(child: Icon(Icons.notifications_sharp)),
          label: 'Notifications',
        ),
        if (_role == 'student') ...[
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner), 
            label: 'Scan',
          ),
        ],
        const NavigationDestination(
          icon: FaIcon(FontAwesomeIcons.carOn),
          label: 'Detect car',
        ),
        const NavigationDestination(icon: Icon(Icons.person), label: 'Service'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: _drawermenu(),
      body: _getBody(),
      bottomNavigationBar: _buttomNavigation(),
    );
  }
}
