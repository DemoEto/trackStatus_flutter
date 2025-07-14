import 'package:flutter/material.dart';

class AcademicProfilePage extends StatefulWidget {
  const AcademicProfilePage({super.key});

  @override
  State<AcademicProfilePage> createState() => _AcademicProfilePageState();
}

class _AcademicProfilePageState extends State<AcademicProfilePage> {
  Widget _profileHeader() {
    return Container(
      color: const Color(0xFF6A58E7),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundImage: AssetImage('assets/user.jpg'), // หรือ NetworkImage
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('WORAWE SOOKSRI',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  Text('Faculty of Agro-Industry',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              InfoColumn(label: 'STUDENT ID', value: '651310003'),
              InfoColumn(label: 'G.P.A.', value: '2.14'),
              InfoColumn(label: 'CREDITS', value: '124'),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Acadeemic Profiles'), centerTitle: true),
      body: _profileHeader()

    );
  }
}

class InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const InfoColumn({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}