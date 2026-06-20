import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/deadline_model.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DatabaseService _db = DatabaseService();
  late Stream<List<Deadline>> _deadlineStream;

  @override
  void initState() {
    super.initState();
    _deadlineStream = _db.getDeadlines();
  }

  void _showAddDeadlineDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final deptController = TextEditingController(text: "CS");
    final semesterController = TextEditingController(text: "BSCS-5");
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
          title: Text("NEW CALENDAR DEADLINE", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Task / Title", labelStyle: TextStyle(color: Colors.white38)),
                ),
                TextField(
                  controller: subjectController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Subject / Module", labelStyle: TextStyle(color: Colors.white38)),
                ),
                TextField(
                  controller: deptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Department", labelStyle: TextStyle(color: Colors.white38)),
                ),
                TextField(
                  controller: semesterController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Semester Class", labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("TARGET DATE", style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10)),
                  subtitle: Text(DateFormat('yyyy-MM-dd | hh:mm a').format(selectedDate), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Icon(Icons.calendar_today_rounded, color: Colors.cyanAccent),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setDialogState(() {
                          selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty && subjectController.text.trim().isNotEmpty) {
                  await _db.addDeadline(
                    titleController.text.trim(),
                    subjectController.text.trim(),
                    selectedDate,
                    department: deptController.text.trim(),
                    semester: semesterController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("COMMITTED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("TASK CONTROL MATRIX", style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent),
            onPressed: _showAddDeadlineDialog,
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: StreamBuilder<List<Deadline>>(
        stream: _deadlineStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("MATRIX DE-SYNC ERROR", style: TextStyle(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          final deadlines = snapshot.data!;
          if (deadlines.isEmpty) {
            return Center(
              child: Text("NO SYSTEM DEADLINES DETECTED", style: GoogleFonts.orbitron(color: Colors.white10, fontSize: 12)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: deadlines.length,
            itemBuilder: (context, index) {
              final deadline = deadlines[index];
              return _buildDeadlineCard(deadline);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeadlineCard(Deadline target) {
    final bool isOverdue = target.dueDate.isBefore(DateTime.now()) && !target.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: target.isCompleted ? Colors.white.withOpacity(0.01) : const Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: target.isCompleted
              ? Colors.greenAccent.withOpacity(0.1)
              : (isOverdue ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              target.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: target.isCompleted ? Colors.greenAccent : (isOverdue ? Colors.redAccent : Colors.cyanAccent),
              size: 24,
            ),
            onPressed: () => _db.toggleDeadline(target.id, target.isCompleted),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.title,
                  style: GoogleFonts.poppins(
                    color: target.isCompleted ? Colors.white38 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: target.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(target.subject, style: TextStyle(color: target.isCompleted ? Colors.white10 : Colors.cyanAccent.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(width: 10),
                    Text("[${target.semester}]", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: isOverdue ? Colors.redAccent : Colors.white24, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('MMM dd, yyyy | hh:mm a').format(target.dueDate),
                      style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.white38, fontSize: 11, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white10),
            onPressed: () => _db.deleteDeadline(target.id),
            hoverColor: Colors.redAccent.withOpacity(0.05),
          )
        ],
      ),
    );
  }
}