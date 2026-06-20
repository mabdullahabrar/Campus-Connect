import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // --- THE UPDATE PROTOCOL ---
  void _updateNameDialog(String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
        title: Text("Modify Identity", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "New Display Name",
            labelStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abort", style: TextStyle(color: Colors.white38))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // 1. Update Firebase Auth Profile
                await user?.updateDisplayName(nameController.text);

                // 2. Update Firestore Database record
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .update({'name': nameController.text});

                await user?.reload();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Sync Changes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        // Added standard explicit theme back button to enable smooth stack popping
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("IDENTITY PORTAL", style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          // Fixed data availability validation step to prevent type assertion errors during pipeline shifts
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? "RevCraaze";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.cyanAccent,
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: Color(0xFF0F172A),
                          child: Icon(Icons.person_rounded, size: 60, color: Colors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name with Edit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 40), // Spacer for centering
                          Text(name,
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.cyanAccent, size: 22),
                            onPressed: () => _updateNameDialog(name),
                          ),
                        ],
                      ),

                      Text(userData['email'] ?? "",
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Info Grid
                Row(
                  children: [
                    _buildInfoCard("Department", userData['department'] ?? "CS", Icons.account_balance_rounded),
                    const SizedBox(width: 15),
                    _buildInfoCard("Semester", userData['semester'] ?? "N/A", Icons.school_rounded),
                  ],
                ),
                const SizedBox(height: 30),

                // Settings List
                _buildSettingsTile(Icons.dark_mode_rounded, "Interface Theme", "Cyber Dark (Active)"),
                _buildSettingsTile(Icons.notifications_active_rounded, "Push Notifications", "Assignments Only"),
                _buildSettingsTile(Icons.security_rounded, "Privacy & Data", "Managed by Firebase"),

                const SizedBox(height: 40),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text("TERMINATE SESSION", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 20),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
      ),
    );
  }
}