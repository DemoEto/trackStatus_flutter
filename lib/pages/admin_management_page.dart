import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../routes/app_route.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Management System')),
      body: ListView(
        children: [
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.userGear,
            title: "Users Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.schoolCircleExclamation,
            title: "School Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.fileContract,
            title: "Attendance Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.busSide,
            title: "Transport Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.rightToBracket,
            title: "Audit & Monitoring",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.download,
            title: "Backup & Export",
            routeName: AppRoutes.usersManagement,
          ),
        ],
      ),
    );
  }
}
