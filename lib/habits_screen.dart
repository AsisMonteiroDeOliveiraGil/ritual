import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
        title: Text(
          'Hábitos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Text(
          'Hábitos',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
