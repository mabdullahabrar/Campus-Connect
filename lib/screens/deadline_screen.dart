import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../models/deadline_model.dart';

class DeadlineScreen extends StatefulWidget {
  const DeadlineScreen({super.key});

  @override
  State<DeadlineScreen> createState() => _DeadlineScreenState();
}

class _DeadlineScreenState extends State<DeadlineScreen> {
  final DatabaseService _db = DatabaseService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Controllers for Dialogs
  final _regNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  // State Variables
  bool _isPrivileged = false; // Permission Gate
  bool _isSyncing = false;
  String _selectedInstitute = "9";
  String _selectedDept = "CS";
  String _selectedSem = "1st";
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  HeadlessInAppWebView? headlessWebView;

  final List<String> _semesters = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"];
  final List<String> _departments = ["CS", "EE", "BBA", "Psychology", "Law"];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _passwordController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    headlessWebView?.dispose();
    super.dispose();
  }

  // Verifies if the current user is a CR, GR, or Admin
  void _checkPermissions() async {
    if (_user != null) {
      String role = await _db.getUserRole(_user.uid);
      if (mounted) {
        setState(() {
          _isPrivileged = (role == 'admin' || role == 'cr' || role == 'gr');
        });
      }
    }
  }

  // --- THE SCRAPER LOGIC ---
  void _startHeadlessSync() async {
    setState(() => _isSyncing = true);

    // Sync Timeout Guard (60s)
    Timer(const Duration(seconds: 60), () {
      if (_isSyncing) {
        setState(() => _isSyncing = false);
        headlessWebView?.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sync timed out. Verify connection."))
          );
        }
      }
    });

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("https://cms.bahria.edu.pk/Logins/Student/Login.aspx")),
      onLoadStop: (controller, url) async {
        String urlStr = url.toString();

        // 1. Handle CMS Login
        if (urlStr.contains("Login.aspx")) {
          await controller.evaluateJavascript(source: """
            document.getElementById('BodyPH_tbEnrollment').value = '${_regNoController.text}';
            document.getElementById('BodyPH_tbPassword').value = '${_passwordController.text}';
            document.getElementById('BodyPH_ddlInstituteID').value = '$_selectedInstitute';
            document.getElementById('BodyPH_ddlSubUserType').value = 'None';
            document.getElementById('BodyPH_btnLogin').click();
          """);
        }

        // 2. Transition to LMS
        if (urlStr.contains("Dashboard.aspx") || urlStr.contains("Default.aspx")) {
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri("https://lms.bahria.edu.pk/Student/Assignments.php")));
        }

        // 3. Scrape Assignment Data
        if (urlStr.contains("Assignments.php")) {
          var assignments = await controller.evaluateJavascript(source: """
            async function scrapeAll() {
              let courseDropdown = document.getElementById('courseId');
              let options = Array.from(courseDropdown.options).filter(o => o.value !== "");
              let results = [];
              for (let option of options) {
                courseDropdown.value = option.value;
                courseDropdown.dispatchEvent(new Event('change')); 
                await new Promise(r => setTimeout(r, 2500));
                let rows = document.querySelectorAll('table tr');
                rows.forEach((row, index) => {
                  if (index > 0 && row.cells.length > 5) {
                    results.push({
                      'title': row.cells[1].innerText.trim(),
                      'subject': option.text.trim(),
                      'deadline': row.cells[row.cells.length - 1].innerText.trim()
                    });
                  }
                });
              }
              return results;
            }
            scrapeAll();
          """);

          if (assignments != null && assignments is List) {
            for (var item in assignments) {
              DateTime dueDate = DateTime.now().add(const Duration(days: 7));
              try { dueDate = DateFormat("dd-MMM-yyyy").parse(item['deadline']); } catch (_) {}
              // Automatically push scraped data to the global Bahria database
              await _db.addDeadline(item['title'], item['subject'], dueDate, department: "CS", semester: "6th");
            }
          }

          setState(() => _isSyncing = false);
          headlessWebView?.dispose();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("LMS Sync Complete!")));
        }
      },
    );
    await headlessWebView?.run();
  }

  void _showManualAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
          title: Text("MANUAL DEPLOYMENT", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(_titleController, "Task Title", false),
                const SizedBox(height: 15),
                _buildDialogField(_subjectController, "Course Name", false),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Semester", _selectedSem, _semesters, (val) => setDialogState(() => _selectedSem = val!))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDropdown("Dept", _selectedDept, _departments, (val) => setDialogState(() => _selectedDept = val!))),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Due Date", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.cyanAccent)),
                  trailing: const Icon(Icons.calendar_month_rounded, color: Colors.cyanAccent),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abort", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () async {
                if (_titleController.text.isNotEmpty) {
                  await _db.addDeadline(_titleController.text, _subjectController.text, _selectedDate, department: _selectedDept, semester: _selectedSem);
                  _titleController.clear(); _subjectController.clear();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Initialize", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLMSLogin() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
          title: Text("SYNC BAHRIA LMS", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(_regNoController, "Enrollment Number", false),
              const SizedBox(height: 15),
              _buildDialogField(_passwordController, "CMS Password", true),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedInstitute,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: "Campus", labelStyle: TextStyle(color: Colors.white38)),
                items: const [
                  DropdownMenuItem(value: "9", child: Text("Islamabad H-11")),
                  DropdownMenuItem(value: "1", child: Text("Islamabad E-8")),
                  DropdownMenuItem(value: "2", child: Text("Karachi")),
                ],
                onChanged: (val) => setDialogState(() => _selectedInstitute = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abort", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () { Navigator.pop(context); _startHeadlessSync(); },
              child: const Text("Sync Grid", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: Text("TASK TRACKER",
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
        actions: [
          // SYNC ICON: Only visible to CR/GR/Admin
          if (_isPrivileged)
            _isSyncing
                ? const Padding(padding: EdgeInsets.all(15), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)))
                : IconButton(icon: const Icon(Icons.sync_rounded, color: Colors.cyanAccent), onPressed: _showLMSLogin)
        ],
      ),
      body: StreamBuilder<List<Deadline>>(
        stream: _db.getDeadlines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          final tasks = snapshot.data!;

          if (tasks.isEmpty) {
            return Center(child: Text("All Clear. No tasks detected.", style: GoogleFonts.orbitron(color: Colors.white10, fontSize: 12)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildDeadlineCard(tasks[index]),
          );
        },
      ),
      // FAB: Only visible to CR/GR/Admin
      floatingActionButton: _isPrivileged
          ? FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        onPressed: _showManualAddDialog,
        child: const Icon(Icons.add_task_rounded, color: Colors.black),
      )
          : null,
    );
  }

  Widget _buildDeadlineCard(Deadline task) {
    bool isOverdue = task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.white.withOpacity(0.01) : const Color(0xFF1E293B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOverdue ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: Colors.cyanAccent,
          onChanged: (val) => _db.toggleDeadline(task.id, task.isCompleted),
        ),
        title: Text(task.title,
            style: GoogleFonts.poppins(
                color: task.isCompleted ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                fontSize: 14)),
        subtitle: Text("${task.subject} • ${DateFormat('MMM dd | hh:mm a').format(task.dueDate)}",
            style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.white38, fontSize: 11)),
        // DELETE ICON: Only visible to CR/GR/Admin
        trailing: _isPrivileged
            ? IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white24, size: 20),
            onPressed: () => _db.deleteDeadline(task.id))
            : null,
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 12)),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}