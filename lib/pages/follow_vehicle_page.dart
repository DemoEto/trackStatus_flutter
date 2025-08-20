import 'package:flutter/material.dart';

class FollowVehiclePage extends StatefulWidget {
  const FollowVehiclePage({super.key});

  @override
  State<FollowVehiclePage> createState() => _FollowVehiclePageState();
}

class _FollowVehiclePageState extends State<FollowVehiclePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detec Vehicle'),
      ),
      body: Column(
        children: [
          Center(
            child: Image.asset('assets/images/avavav.jpg'),
          ),
          Padding(
            padding: EdgeInsetsGeometry.directional(top: 10),
            child: Text('Vehicle Status: '),
          )
        ],
      ),
    );
  }
}