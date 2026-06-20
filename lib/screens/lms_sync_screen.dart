import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class LmsSyncScreen extends StatefulWidget {
  const LmsSyncScreen({super.key});

  @override
  State<LmsSyncScreen> createState() => _LmsSyncScreenState();
}

class _LmsSyncScreenState extends State<LmsSyncScreen> {
  InAppWebViewController? webViewController;
  final DatabaseService _db = DatabaseService();

  // The "Magic" Javascript that reads the assignment table
  final String scraperJS = """
    (function() {
      var assignments = [];
      var rows = document.querySelectorAll('table tr'); 
      rows.forEach((row, index) => {
        if(index > 0) { 
          var cols = row.querySelectorAll('td');
          if(cols.length >= 3) {
            assignments.push({
              'title': cols[1].innerText.trim(),
              'subject': cols[0].innerText.trim(),
              'date': cols[2].innerText.trim()
            });
          }
        }
      });
      return assignments;
    })();
  """;

  void _extractAndSync() async {
    var result = await webViewController?.evaluateJavascript(source: scraperJS);

    if (result != null && result is List) {
      int count = 0;
      for (var item in result) {
        // FIXED: Added required 'department' and 'semester' parameters
        // Defaulting to CS and 6th Semester based on your profile
        await _db.addDeadline(
            item['title'],
            item['subject'],
            DateTime.now().add(const Duration(days: 7)),
            department: "CS", // You can change this to a dynamic variable if needed
            semester: "6th"   // You can change this to a dynamic variable if needed
        );
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.cyanAccent,
            content: Text("Successfully synced $count assignments!",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("LMS SYNC HUB",
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.cyanAccent, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded, color: Colors.cyanAccent),
            onPressed: _extractAndSync,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.cyanAccent.withOpacity(0.1),
            child: Text(
              "Log in -> 'My Assignments' -> Tap Download Icon",
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://cms.bahria.edu.pk/"),
              ),
              onWebViewCreated: (controller) => webViewController = controller,
              // Adding a loading indicator for better UX
              onLoadStart: (controller, url) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Loading Bahria Portal..."), duration: Duration(seconds: 1)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}