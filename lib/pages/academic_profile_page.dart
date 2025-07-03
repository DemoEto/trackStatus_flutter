import 'package:flutter/material.dart';

class AcademicProfilePage extends StatefulWidget {
  const AcademicProfilePage({super.key});

  @override
  State<AcademicProfilePage> createState() => _AcademicProfilePageState();
}

class _AcademicProfilePageState extends State<AcademicProfilePage> {

  Widget _topbody() {
    return Column(

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acadeemic Profiles',),
        centerTitle: true,
      ),
      body: Container(
        
      )
    );
  }
}