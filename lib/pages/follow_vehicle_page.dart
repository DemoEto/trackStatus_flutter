import 'package:flutter/material.dart';

class FollowVehiclePage extends StatefulWidget {
  const FollowVehiclePage({super.key});

  @override
  State<FollowVehiclePage> createState() => _FollowVehiclePageState();
}

class _FollowVehiclePageState extends State<FollowVehiclePage> {
  String status = "";
  Widget _takeStudent() {
    return Column(
      children: [
        Center(child: Image.asset('assets/images/school-bus.gif')),
        Padding(
          padding: EdgeInsetsGeometry.directional(top: 10),
          child: Text('กำลังรับนักเรียนไปโรงเรียน', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
  Widget _aliveSchool() {
    return Column(
      children: [
        Center(child: Image.asset('assets/images/aliveschool.gif')),
        Padding(
          padding: EdgeInsetsGeometry.directional(top: 10),
          child: Text('กำลังรับนักเรียนไปโรงเรียน', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
  Widget _goSchool() {
    return Column(
      children: [
        Center(child: Image.asset('assets/images/goschool.gif')),
        Padding(
          padding: EdgeInsetsGeometry.directional(top: 10),
          child: Text('กำลังรับนักเรียนไปโรงเรียน', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detect Vehicle')),
      body: Placeholder()
    );
  }
}
