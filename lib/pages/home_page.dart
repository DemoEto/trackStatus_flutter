import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackstatus_flutter/routes/app_route.dart';

import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<User?> _reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // โหลดข้อมูลล่าสุด
    return FirebaseAuth.instance.currentUser; // รีเทิร์น user ที่ reload แล้ว
  }
  
  int _selectedIndex = 0;

  Future<void> signOut() async {
    await AuthService().signOut();
  }

  Widget _title() {
    return const Text('Firebase Auth');
  }

  Widget _userUid() {
    // ดึง AuthService จาก Provider
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    print('🔄 displayName = ${user?.displayName}');
    return Column(
      children: [
        Text(user?.email ?? 'User email'),
        Text(user?.displayName ?? 'Name')
      ],
    );
  }

  Widget _signOutButton() {
    return ElevatedButton(onPressed: signOut, child: const Text('Signout'));
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
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index == 2) {
          // สมมติ Scan เป็นปุ่มที่ 3
        }
        if (index == 4) {
          context.push(AppRoutes.service);
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      indicatorColor: const Color.fromARGB(255,197, 211, 232),
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
        NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        NavigationDestination(
          icon: Badge(label: Text('2'), child: Icon(Icons.messenger_sharp)),
          label: 'Messages',
        ),
        NavigationDestination(icon: Icon(Icons.person), label: 'Service'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _title()),
      drawer: _drawermenu(),
      
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_userUid(), _signOutButton()],
        ),
      ),
      bottomNavigationBar: _buttomNavigation(),
    );
  }
}
