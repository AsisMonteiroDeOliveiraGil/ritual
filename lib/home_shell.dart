import 'package:flutter/material.dart';
import 'package:ritual/habits_screen.dart';
import 'package:ritual/today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFC63C54);
    const unselectedColor = Colors.white54;
    const bg = Color(0xFF151515);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          HabitsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        backgroundColor: bg,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Hábitos',
          ),
        ],
      ),
    );
  }
}
