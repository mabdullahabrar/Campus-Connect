import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GPAScreen extends StatefulWidget {
  const GPAScreen({super.key});

  @override
  State<GPAScreen> createState() => _GPAScreenState();
}

class _GPAScreenState extends State<GPAScreen> {
  // Data structure for the academic grid
  final List<Map<String, dynamic>> _courses = [
    {"credits": 3, "grade": "A"},
  ];

  final List<TextEditingController> _controllers = [
    TextEditingController(text: "Course 1")
  ];

  final Map<String, double> _gradePoints = {
    "A": 4.0, "A-": 3.67, "B+": 3.33, "B": 3.0, "B-": 2.67,
    "C+": 2.33, "C": 2.0, "C-": 1.67, "D+": 1.33, "D": 1.0, "F": 0.0
  };

  double _calculatedGPA = 0.0;
  int _totalCredits = 3;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addCourse() {
    setState(() {
      _courses.add({"credits": 3, "grade": "A"});
      _controllers.add(TextEditingController(text: "Course ${_courses.length}"));
    });
    _calculateGPA();
  }

  void _removeCourse(int index) {
    if (_courses.length <= 1) return; // Maintain at least one entry point
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _courses.removeAt(index);
    });
    _calculateGPA();
  }

  void _calculateGPA() {
    double totalPoints = 0;
    int creditsAccrued = 0;

    for (int i = 0; i < _courses.length; i++) {
      double points = _gradePoints[_courses[i]['grade']]!;
      int credits = _courses[i]['credits'];
      totalPoints += (points * credits);
      creditsAccrued += credits;
    }

    setState(() {
      _totalCredits = creditsAccrued;
      _calculatedGPA = creditsAccrued == 0 ? 0.0 : totalPoints / creditsAccrued;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("GPA ARCHITECT",
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          _buildGpaDashboard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Divider(color: Colors.white10),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _courses.length,
              itemBuilder: (context, index) => _buildCourseNode(index),
            ),
          ),
          _buildActionDock(),
        ],
      ),
    );
  }

  Widget _buildGpaDashboard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SGPA PROJECTION",
                  style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(_calculatedGPA.toStringAsFixed(2),
                  style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 48, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("TOTAL LOAD", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10)),
              Text("$_totalCredits Credits", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("${_courses.length} Courses", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCourseNode(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _controllers[index],
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: "Course identifier...",
                hintStyle: TextStyle(color: Colors.white10),
                border: InputBorder.none,
              ),
            ),
          ),
          _buildSelector<int>(
              value: _courses[index]['credits'],
              items: [1, 2, 3, 4],
              onChanged: (val) {
                setState(() => _courses[index]['credits'] = val!);
                _calculateGPA();
              },
              label: "Cr"
          ),
          const SizedBox(width: 12),
          _buildSelector<String>(
            value: _courses[index]['grade'],
            items: _gradePoints.keys.toList(),
            onChanged: (val) {
              setState(() => _courses[index]['grade'] = val!);
              _calculateGPA();
            },
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withOpacity(0.2), size: 20),
            onPressed: () => _removeCourse(index),
            hoverColor: Colors.redAccent.withOpacity(0.1),
          )
        ],
      ),
    );
  }

  Widget _buildSelector<T>({required T value, required List<T> items, required Function(T?) onChanged, String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<T>(
        value: value,
        dropdownColor: const Color(0xFF1E293B),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.cyanAccent, size: 16),
        style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text("$i ${label ?? ''}"))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionDock() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addCourse,
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                label: const Text("EXPAND GRID"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white70,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _calculateGPA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 10,
                  shadowColor: Colors.cyanAccent.withOpacity(0.3),
                ),
                child: Text("RUN ANALYSIS", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}