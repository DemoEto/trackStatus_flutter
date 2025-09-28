import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    late final PlatformWebViewControllerCreationParams finalParams;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // ถ้าเป็น iOS
      finalParams =
          WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      // ถ้าเป็น Android
      finalParams =
          AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    } else {
      finalParams = params;
    }

    // สร้าง WebViewController
    webViewController = WebViewController.fromPlatformCreationParams(finalParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // inject JavaScript เพื่อลบ cookie popup
            webViewController.runJavaScript('''
              var cookieBanner = document.querySelector(".cookie-banner, .cookie-consent, #cookie-popup");
              if (cookieBanner) {
                cookieBanner.style.display = "none";
              }
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.rmutl.ac.th/'));

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

  

  Widget _buildDrawer() {
    // Determine which destinations to show based on role
    List<Map<String, dynamic>> navigationItems = [
      {
        'icon': Icons.home,
        'label': 'หน้าหลัก',
        'route': '/',
      },
    ];

    // Add QR Scan for students only
    if (_role != null && _role == 'student') {
      navigationItems.add({
        'icon': Icons.qr_code_scanner,
        'label': 'สแกน QR',
        'route': AppRoutes.qrScan,
      });
      
      // Add Homework for students only
      navigationItems.add({
        'icon': Icons.book,
        'label': 'การบ้าน',
        'route': AppRoutes.homework,
      });
    }
    
    // Add Homework Assignment for teachers only
    if (_role != null && _role == 'teacher') {
      navigationItems.add({
        'icon': Icons.assignment,
        'label': 'มอบหมายการบ้าน',
        'route': '${AppRoutes.homework}/assignment',
      });
    }
    
    // Add QR Check-in for teachers only
    if (_role != null && _role == 'teacher') {
      navigationItems.add({
        'icon': Icons.qr_code,
        'label': 'เช็คชื่อ QR',
        'route': AppRoutes.qrCheckin,
      });
    }

    // Add Follow Vehicle for drivers only
    if (_role != null && _role == 'driver') {
      navigationItems.add({
        'icon': FontAwesomeIcons.carOn,
        'label': 'ติดตามรถ',
        'route': AppRoutes.followVehicle,
      });
    }

    // Add Admin Management for admins only
    if (_role != null && _role == 'admin') {
      navigationItems.add({
        'icon': Icons.admin_panel_settings,
        'label': 'ผู้ดูแลระบบ',
        'route': AppRoutes.adminManagement,
      });
    }

    // Add scan history for all users
    navigationItems.add({
      'icon': Icons.qr_code,
      'label': 'ประวัติการสแกน',
      'route': AppRoutes.attendHistory,
    });

    // Add service/profile page for all users
    navigationItems.add({
      'icon': Icons.person,
      'label': 'บริการ',
      'route': AppRoutes.service,
    });

    // Load user data for drawer header
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Drawer(
        child: Center(
          child: Text('กำลังโหลด...'),
        ),
      );
    }

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user information
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserInfo(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const UserAccountsDrawerHeader(
                  accountName: Text('กำลังโหลด...'),
                  accountEmail: Text('กำลังโหลด...'),
                  currentAccountPicture: CircleAvatar(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userInfo = snapshot.data!;
              final name = userInfo['name'] ?? 'ไม่ระบุชื่อ';
              final role = userInfo['role'] ?? 'ไม่ระบุบทบาท';
              final email = userInfo['email'] ?? user.email ?? 'ไม่ระบุอีเมล';

              return UserAccountsDrawerHeader(
                accountName: Text(name),
                accountEmail: Text('$email ($role)'),
                currentAccountPicture: CircleAvatar(
                  child: Text(name.substring(0, 1).toUpperCase()),
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 197, 211, 232), // Same color as app
                ),
              );
            },
          ),
          
          // Navigation list items
          Expanded(
            child: ListView.builder(
              itemCount: navigationItems.length + 1, // +1 for logout item
              itemBuilder: (context, index) {
                if (index == navigationItems.length) {
                  // This is the logout item
                  return ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('ออกจากระบบ'),
                    onTap: () async {
                      Navigator.of(context).pop(); // Close drawer
                      final contextToUse = context; // Capture context before async gap
                      await AuthService().signOut(); // logout
                      if (contextToUse.mounted) {
                        contextToUse.go(AppRoutes.login); // Use go to navigate to login
                      }
                    },
                  );
                }
                
                final item = navigationItems[index];
                return ListTile(
                  leading: Icon(item['icon']),
                  title: Text(item['label']),
                  onTap: () {
                    // Close the drawer and navigate to the selected route
                    Navigator.of(context).pop(); // Close drawer
                    if (item['route'] == '/') {
                      context.go('/'); // Go to the initial home route
                    } else if (item['route'].isNotEmpty) {
                      context.go(item['route']);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get user info
  Future<Map<String, dynamic>?> _getUserInfo(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return {
          'name': userData['name'],
          'role': userData['role'],
          'email': userData['email'],
        };
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          // Notification icon moved to top right
          IconButton(
            icon: const Badge(child: Icon(Icons.notifications_sharp)),
            onPressed: () {
              context.go('/notifications'); // Navigate to notifications
            },
          ),
        ],
      ),
      body: _getBody(),
      drawer: _buildDrawer(),
    );
  }
}
