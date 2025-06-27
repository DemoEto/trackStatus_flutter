import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../services/auth_service.dart';
import '../routes/app_route.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = AuthService().currentUser;

  Future<void> signOut() async {
    await AuthService().signOut();
  }

  Widget _title() {
    return const Text('Firebase Auth');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
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
              'เมนู',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('ข้อมูลการมาเรียน'),
            onTap: () {
              context.push(AppRoutes.attendHistory);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('ข้อมูลการมาเรียนรายเดือน'),
            onTap: () {
              Navigator.pop(context); // ปิด Drawer
              Navigator.pushNamed(
                context,
                '/attendance-report',
              ); // ชื่อ route ที่จะไป
            },
          ),

          ListTile(
            leading: const Icon(Icons.car_crash),
            title: const Text('ติดตามสถานะรถโรงเรียน'),
            onTap: () {
              Navigator.pop(context); // ปิด Drawer
              Navigator.pushNamed(context, '/profile'); // ไปยังหน้าโปรไฟล์
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize_rounded),
            title: const Text('ระบบส่งการบ้านและสั่งงานนักเรียน'),
            onTap: () {
              Navigator.pop(context); // ปิด Drawer
              Navigator.pushNamed(context, '/profile'); // ไปยังหน้าโปรไฟล์
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('ตั้งค่า'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () async {
              await AuthService().signOut(); // logout
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
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
    );
  }
}
