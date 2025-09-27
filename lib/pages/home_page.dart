import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';


import '../routes/app_route.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final WebViewController webViewController;

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
  }



  Widget _userInfoBar() {
    final userService = UserService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Text("ไม่พบผู้ใช้");

    return StreamBuilder<StudentData?>(
      stream: userService.streamUser(uid),
      builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(user.name),Text(user.role),
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await AuthService().signOut(); // logout
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buttomNavigation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Not logged in")));
    }
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index == 2) {
          context.push(
            AppRoutes.qrScan,
            // TODO: Send session to qrCheckin Page
            // extra: {
            //   'uid': user.uid,
            //   'displayName': user.displayName ?? 'No name',
            // },
          );
        }
        if (index == 3) {
          context.push(AppRoutes.followVehicle);
        }
        if (index == 4) {
          context.push(AppRoutes.service);
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      indicatorColor: const Color.fromARGB(255, 197, 211, 232),
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Badge(child: Icon(Icons.notifications_sharp)),
          label: 'Notifications',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner), 
          label: 'Scan'
        ),
        NavigationDestination(
          icon: FaIcon(FontAwesomeIcons.carOn),
          label: 'Detect car',
        ),
        NavigationDestination(
          icon: Icon(Icons.person), 
          label: 'Service'
        ),
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
