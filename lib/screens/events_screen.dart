import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final DatabaseService _db = DatabaseService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Primary Controllers for deployment
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();

  // Optional Coordinate Controllers
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // State Variables
  bool _isPrivileged = false; // The gatekeeper variable
  String _searchQuery = "";
  DateTime _eventDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Verifies if the current user has the scope to manage events
  void _checkPermissions() async {
    if (_user != null) {
      String role = await _db.getUserRole(_user.uid);
      if (mounted) {
        setState(() {
          // CR, GR, and Admin are granted deployment permissions
          _isPrivileged = (role == 'admin' || role == 'cr' || role == 'gr');
        });
      }
    }
  }

  // Launches maps using the coordinates stored in the Event model
  Future<void> _openMap(double lat, double lng) async {
    final String googleMapsUrl = "https://maps.google.com/?q=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not establish Map link")),
        );
      }
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
          title: Text("DEPLOY EVENT",
              style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 1.5)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(_titleController, "Event Title"),
                _buildField(_descController, "Short Description"),
                _buildField(_locController, "Location (e.g. Lab 4)"),
                const SizedBox(height: 15),

                Text("Optional Coordinates",
                    style: GoogleFonts.orbitron(color: Colors.white24, fontSize: 10)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildField(_latController, "Latitude")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(_lngController, "Longitude")),
                  ],
                ),

                const SizedBox(height: 15),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Date & Time", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                  subtitle: Text(DateFormat('MMM dd, hh:mm a').format(_eventDate),
                      style: const TextStyle(color: Colors.cyanAccent)),
                  trailing: const Icon(Icons.calendar_month_rounded, color: Colors.cyanAccent),
                  onTap: () async {
                    DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: _eventDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030)
                    );
                    if (d != null) {
                      if (!mounted) return;
                      TimeOfDay? t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now()
                      );
                      if (t != null) setDialogState(() => _eventDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  },
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
                if (_titleController.text.isNotEmpty) {
                  // Fallback to Bahria H-11 Coordinates if fields are empty
                  double lat = double.tryParse(_latController.text) ?? 33.6493;
                  double lng = double.tryParse(_lngController.text) ?? 73.0244;

                  await _db.addEvent(
                      _titleController.text,
                      _descController.text,
                      _eventDate,
                      _locController.text,
                      lat,
                      lng
                  );

                  _titleController.clear();
                  _descController.clear();
                  _locController.clear();
                  _latController.clear();
                  _lngController.clear();

                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Initialize",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: Text("EVENTS HORIZON",
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          // Search Transmission Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search upcoming events...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white10)
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.cyanAccent)
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<CampusEvent>>(
              stream: _db.getEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

                final events = snapshot.data!.where((e) =>
                    e.title.toLowerCase().contains(_searchQuery)
                ).toList();

                if (events.isEmpty) {
                  return Center(child: Text("No upcoming transmissions.",
                      style: GoogleFonts.orbitron(color: Colors.white10, fontSize: 12)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _buildEventCard(events[index]),
                );
              },
            ),
          ),
        ],
      ),
      // FAB: Only visible to CR, GR, and Admin
      floatingActionButton: _isPrivileged
          ? FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add_alert_rounded, color: Colors.black),
      )
          : null,
    );
  }

  Widget _buildEventCard(CampusEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(event.title,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(
              event.description,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigation button (Everyone)
                IconButton(
                  icon: const Icon(Icons.map_rounded, color: Colors.cyanAccent, size: 18),
                  onPressed: () => _openMap(event.latitude, event.longitude),
                ),
                // Purge button (Privileged only)
                if (_isPrivileged)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _db.deleteEvent(event.id),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.cyanAccent, size: 14),
                const SizedBox(width: 5),
                Text(event.location, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                const Icon(Icons.access_time_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 5),
                Text(
                    DateFormat('MMM dd • hh:mm a').format(event.date),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l) {
    return kTextField(
      controller: c,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: (l == "Latitude" || l == "Longitude")
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.white24),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))
      ),
    );
  }

  // Custom added proxy method to resolve compilation definitions safely
  Widget kTextField({
    required TextEditingController controller,
    TextStyle? style,
    TextInputType? keyboardType,
    InputDecoration? decoration,
  }) {
    return TextField(
      controller: controller,
      style: style,
      keyboardType: keyboardType,
      decoration: decoration,
    );
  }
}