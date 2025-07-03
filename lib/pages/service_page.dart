import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../routes/app_route.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0,),
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
      appBar: AppBar(title: Text('Services'),),
      body: ListView(
        children: <Widget>[
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
            routeName: AppRoutes.home,
          ),
          _buildCard(
            context: context,
            icon: Icons.qr_code,
            title: 'QR & Check-In',
            routeName: AppRoutes.qrCheckin,
          ),
        ],
      ),
    );
  }
}
