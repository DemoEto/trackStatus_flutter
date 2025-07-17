import 'package:flutter/material.dart';

class AcademicProfilePage extends StatefulWidget {
  const AcademicProfilePage({super.key});

  @override
  State<AcademicProfilePage> createState() => _AcademicProfilePageState();
}

class _AcademicProfilePageState extends State<AcademicProfilePage> {
  Widget _profileHeader() {
    return Container(
      color: const Color(0xFFA6AEBF),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundImage: AssetImage('assets/images/avavav.jpg'), // หรือ NetworkImage
              ),
              const SizedBox(width: 16), 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: const [
                  Text('KANATIP WONGKITI',
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

  Widget _tabBar(){
    return const TabBar(
      labelColor: Colors.deepPurple,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.deepPurple,
      tabs: [
        Tab(text: 'Transcript'),
        Tab(text: 'GPA Plan'),
        Tab(text: 'Advisor'),
      ],
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text('Acadeemic Profiles'), centerTitle: true),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              _profileHeader(),
              _tabBar(),
              Expanded(child: AcademicRecordTable()),
            ],
          ),
        ),
      ),
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

class AcademicRecordTable extends StatelessWidget {
  const AcademicRecordTable({super.key});

  final List<Map<String, dynamic>> data = const [
    {'code': '001101', 'course': 'Fundamental English 1', 'credit': 3, 'grade': 'F'},
    {'code': '202101', 'course': 'Basic Biology 1', 'credit': 3, 'grade': 'D+'},
    {'code': '202103', 'course': 'Biology Laboratory 1', 'credit': 1, 'grade': 'B+'},
    {'code': '203103', 'course': 'General Chemistry 1', 'credit': 3, 'grade': 'W'},
    {'code': '203107', 'course': 'General Chemistry Lab 1', 'credit': 1, 'grade': 'C'},
    {'code': '204100', 'course': 'IT and Modern Life', 'credit': 3, 'grade': 'C'},
    {'code': '206103', 'course': 'Calculus 1', 'credit': 3, 'grade': 'F'},
    {'code': '207123', 'course': 'Physics for Agro Students', 'credit': 3, 'grade': 'C'},
    {'code': '207173', 'course': 'Physics Lab for Agro Students', 'credit': 1, 'grade': 'B+'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Semester : 1/2565',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(80),
            1: FlexColumnWidth(),
            2: FixedColumnWidth(50),
            3: FixedColumnWidth(50),
          },
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          children: [
            const TableRow(
              children: [
                Text('Code', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Course', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            ...data.map((course) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(course['code']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(course['course']),
                ),
                Center(child: Text(course['credit'].toString())),
                Center(child: Text(course['grade'])),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          color: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Accumulated Credits:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('18     1.42', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }
}