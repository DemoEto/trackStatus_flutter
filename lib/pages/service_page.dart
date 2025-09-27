import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../routes/app_route.dart';
import '../services/user_service.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          onTap: () => context.push(routeName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Text("ไม่พบผู้ใช้");
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: StreamBuilder<StudentData?>(
        stream: userService.streamUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("ไม่พบข้อมูล"));
          }

          final student = snapshot.data!;
          final role = student.role;

          // list เก็บการ์ดที่จะแสดง
          final List<Widget> cards = [];

          // เมนูที่ทุก role เข้าถึงได้
          cards.addAll([
            _buildCard(
              context: context,
              icon: FontAwesomeIcons.addressBook,
              title: 'Academic Profiles',
              routeName: AppRoutes.academicProfile,
            ),
            _buildCard(
              context: context,
              icon: FontAwesomeIcons.car,
              title: 'My Vehicle',
              routeName: AppRoutes.vehicle,
            ),
            _buildCard(
              context: context,
              icon: Icons.qr_code,
              title: 'QR & Check-In',
              routeName: AppRoutes.qrCheckin,
            ),
          ]);

          // เพิ่มเมนูเฉพาะ admin
          if (role == "admin") {
            cards.add(
              _buildCard(
                context: context,
                icon: Icons.admin_panel_settings,
                title: 'ADMIN Management',
                routeName: AppRoutes.adminManagement,
              ),
            );
          }

          return ListView(children: cards);
        },
      ),
    );
  }
}