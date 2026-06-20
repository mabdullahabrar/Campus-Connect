import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/note_model.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final DatabaseService _db = DatabaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isPrivileged = false; // The gatekeeper for CR/GR/Admin access

  // Input Controllers for the Upload Dialog
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _courseController = TextEditingController();

  // State variables for uploading and filtering
  String _uploadSemester = "1st";
  String _uploadDept = "CS";
  String _searchQuery = "";
  String _filterSemester = "All";
  String _filterDept = "All";

  final List<String> _semesters = ["All", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"];
  final List<String> _departments = ["All", "CS", "EE", "BBA", "Psychology", "Law"];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  // Verifies if the current user has the scope to edit the hub
  void _checkPermissions() async {
    if (_currentUser != null) {
      String role = await _db.getUserRole(_currentUser.uid);
      if (mounted) {
        setState(() {
          _isPrivileged = (role == 'admin' || role == 'cr' || role == 'gr');
        });
      }
    }
  }

  // Launches the broadcast dialog for authorized users
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("BROADCAST RESOURCE",
              style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 1.5)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(_titleController, "Title (e.g. Lab Journal 5)"),
                const SizedBox(height: 15),
                _buildDialogField(_courseController, "Course Name (e.g. AI)"),
                const SizedBox(height: 15),
                _buildDialogField(_linkController, "Resource Link (G-Drive/Mega)"),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Semester", _uploadSemester, _semesters.where((s) => s != "All").toList(), (val) => setDialogState(() => _uploadSemester = val!))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDropdown("Dept", _uploadDept, _departments.where((d) => d != "All").toList(), (val) => setDialogState(() => _uploadDept = val!))),
                  ],
                ),
              ],
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
                if (_titleController.text.isNotEmpty && _linkController.text.isNotEmpty) {
                  String verifiedLink = _linkController.text.trim();

                  // ADDED: Auto-inject missing web protocols safely before saving to Firestore grid
                  if (!verifiedLink.startsWith('http://') && !verifiedLink.startsWith('https://')) {
                    verifiedLink = 'https://$verifiedLink';
                  }

                  await _db.addNote(
                    _titleController.text.trim(),
                    _uploadDept,
                    verifiedLink,
                    _currentUser?.displayName ?? "Student",
                    semester: _uploadSemester,
                    course: _courseController.text.trim(),
                  );
                  _titleController.clear();
                  _linkController.clear();
                  _courseController.clear();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Initialize", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Purge Resource?", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Delete '$title' from the hub? This transmission cannot be recovered.",
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _db.deleteNote(id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
        title: Text("RESOURCE HUB",
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          // Cyber Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search transmissions...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent)),
              ),
            ),
          ),

          // Horizontal Filter Chips
          _buildFilterRow("Semester", _filterSemester, _semesters, (val) => setState(() => _filterSemester = val)),
          _buildFilterRow("Sector", _filterDept, _departments, (val) => setState(() => _filterDept = val)),

          const SizedBox(height: 10),

          // Resource Feed
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _db.getNotes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

                final notes = snapshot.data!.where((note) {
                  bool matchesSearch = note.title.toLowerCase().contains(_searchQuery) || note.course.toLowerCase().contains(_searchQuery);
                  bool matchesSemester = _filterSemester == "All" || note.semester == _filterSemester;
                  bool matchesDept = _filterDept == "All" || note.department == _filterDept;
                  return matchesSearch && matchesSemester && matchesDept;
                }).toList();

                if (notes.isEmpty) {
                  return Center(child: Text("No data found in this sector.", style: GoogleFonts.poppins(color: Colors.white24)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: notes.length,
                  itemBuilder: (context, index) => _buildNoteCard(notes[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isPrivileged
          ? FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        elevation: 10,
        onPressed: _showUploadDialog,
        child: const Icon(Icons.add_link_rounded, color: Colors.black),
      )
          : null,
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(note.title,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(note.course, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
            Text("${note.semester} Sem • ${note.department} • By ${note.uploaderName}",
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPrivileged)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDelete(note.id, note.title),
              ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.cyanAccent, size: 20),
                onPressed: () async {
                  String urlString = note.fileUrl.trim();

                  // EDITED: Extra fallback protocol sanity check for safety during launch runtime
                  if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                    urlString = 'https://$urlString';
                  }

                  try {
                    final Uri uri = Uri.parse(urlString);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not open launch link.")),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String label, String selected, List<String> items, Function(String) onSelected) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = selected == items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(items[index]),
              selected: isSelected,
              onSelected: (val) => onSelected(items[index]),
              selectedColor: Colors.cyanAccent,
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.black : Colors.white60,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              showCheckmark: false,
              side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.white10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
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
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}