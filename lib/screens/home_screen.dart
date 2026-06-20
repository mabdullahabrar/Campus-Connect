import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Added to format summary dates cleanly
import '../services/database_service.dart';
import '../models/deadline_model.dart';
import '../models/note_model.dart';
import '../models/event_model.dart'; // Added to support the CampusEvent data stream
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;

  // Variables for identity tracking
  late String _displayName;
  String _userRole = "STUDENT";

  @override
  void initState() {
    super.initState();
    _displayName = user?.displayName ?? "RevCraaze";
    _fetchUserRole();
  }

  // Fetches the user's scope (Admin/CR/Student) for the badge display
  void _fetchUserRole() async {
    if (user != null) {
      String role = await _db.getUserRole(user!.uid);
      if (mounted) {
        setState(() {
          _userRole = role.toUpperCase();
        });
      }
    }
  }

  void _editProfileName() {
    final TextEditingController nameController = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Update Identity", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "New Username",
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await user?.updateDisplayName(nameController.text);
                // Sync to Firestore for global consistency
                await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                  'name': nameController.text
                });
                await user?.reload();
                setState(() {
                  _displayName = nameController.text;
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
        centerTitle: false,
        title: Text("CAMPUS CONNECT",
            style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // --- SECTION 1: IDENTITY HUB ---
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, anim, secAnim) => const ProfileScreen(),
                        transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF0F172A),
                      child: Icon(Icons.person_rounded, color: Colors.cyanAccent, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                    builder: (context, snapshot) {
                      String displayID = "---";
                      String name = _displayName;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        displayID = data['enrollment'] ?? "N/A";
                        name = data['name'] ?? _displayName;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              // User Scope/Rank Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 0.5)
                                ),
                                child: Text(_userRole, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Text(displayID, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white24),
                  onPressed: _editProfileName,
                )
              ],
            ),
            const SizedBox(height: 25),

            // --- SECTION 2: SEMESTER GOAL TRACKER ---
            StreamBuilder<List<Deadline>>(
              stream: _db.getDeadlines(),
              builder: (context, snapshot) {
                int total = snapshot.data?.length ?? 0;
                int completed = snapshot.data?.where((d) => d.isCompleted).length ?? 0;
                double progress = total == 0 ? 0 : completed / total;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.cyanAccent.withOpacity(0.15), Colors.purpleAccent.withOpacity(0.05)],
                    ),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Semester Goal", style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        color: Colors.cyanAccent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$completed of $total Tasks Done", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                          Text(total - completed > 0 ? "${total - completed} Pending" : "All Clear!", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // --- ADDED FEATURE: URGENT DEADLINES FEED ---
            Text("Urgent Deadlines", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<Deadline>>(
              stream: _db.getDeadlines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final pendingTasks = snapshot.data!.where((d) => !d.isCompleted).toList();

                // Sort by due date chronologically
                pendingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                final urgentTasks = pendingTasks.take(3).toList();

                if (urgentTasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text("No urgent deadlines listed.", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
                  );
                }

                return Column(
                  children: urgentTasks.map((task) {
                    bool isOverdue = task.dueDate.isBefore(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isOverdue ? Colors.redAccent.withOpacity(0.2) : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.label_important_outline_rounded, color: isOverdue ? Colors.redAccent : Colors.orangeAccent, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text("${task.subject} • ${task.semester}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd').format(task.dueDate),
                            style: TextStyle(color: isOverdue ? Colors.redAccent : Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- ADDED FEATURE: UPCOMING BROADCASTS FEED ---
            Text("Upcoming Events", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<CampusEvent>>(
              stream: _db.getEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final futureEvents = snapshot.data!.where((e) => e.date.isAfter(DateTime.now())).toList();

                // Sort by date chronologically
                futureEvents.sort((a, b) => a.date.compareTo(b.date));
                final upcomingEvents = futureEvents.take(3).toList();

                if (upcomingEvents.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text("No upcoming active events.", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
                  );
                }

                return Column(
                  children: upcomingEvents.map((event) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.campaign_rounded, color: Colors.cyanAccent, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text(event.location, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd').format(event.date),
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- SECTION 3: REAL-TIME ACTIVITY ---
            Text("Real-Time Activity", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            StreamBuilder<List<Note>>(
              stream: _db.getNotes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("No recent activity.", style: GoogleFonts.poppins(color: Colors.white38)),
                  );
                }
                // Showing the 3 most recent notes added to the platform
                final recentNotes = snapshot.data!.reversed.take(3).toList();

                return Column(
                  children: recentNotes.map((note) => _buildUpdateItem(
                      Icons.cloud_download_rounded,
                      "${note.uploaderName} shared ${note.title}",
                      note.course // Changed to Course for better context
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Activity Card UI
  Widget _buildUpdateItem(IconData icon, String text, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}