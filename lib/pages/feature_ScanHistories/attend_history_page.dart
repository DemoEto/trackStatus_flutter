import 'package:flutter/material.dart';

class AttendHistoryPage extends StatefulWidget {
  const AttendHistoryPage({super.key});

  @override
  State<AttendHistoryPage> createState() => _AttendHistoryPageState();
}

class _AttendHistoryPageState extends State<AttendHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendent History Student'),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
      ),
    );
  }
}