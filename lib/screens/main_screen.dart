import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'deadline_screen.dart'; // Direct alignment to your layout
import 'notes_screen.dart';
import 'events_screen.dart';
import 'gpa_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const DeadlineScreen(), // Pointing safely to your multi-featured system view
    const NotesScreen(),
    const EventsScreen(),
    const GPAScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.cyanAccent,
              unselectedItemColor: Colors.white30,
              selectedLabelStyle: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 9),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Tasks'),
                BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Notes'),
                BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Events'),
                BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: 'GPA'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}