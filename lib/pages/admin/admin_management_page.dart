import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../routes/app_route.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.Theme.of(context).colorScheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => context.push(routeName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.userGear,
            title: "Users Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.school,
            title: "School Management",
            routeName: AppRoutes.usersManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.fileContract,
            title: "Attendance Management",
            routeName: AppRoutes.attendanceManagement,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.bus,
            title: "Transport Management",
            routeName: AppRoutes.vehicle,
          ),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.bell,
            title: "Notification Management",
            routeName: AppRoutes.notificationManagement,
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
