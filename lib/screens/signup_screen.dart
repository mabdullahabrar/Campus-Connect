import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();

  // Controllers for data input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deptController = TextEditingController(text: "Computer Science");
  final _semesterController = TextEditingController();
  final _enrollmentController = TextEditingController();

  // Clean up memory when screen is destroyed
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deptController.dispose();
    _semesterController.dispose();
    _enrollmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // FIXED: Changed 'child' to 'body'
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
                "ACTIVATE IDENTITY",
                style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent
                )
            ),
            const SizedBox(height: 30),

            _buildTextField(_nameController, "Full Name", Icons.person_outline_rounded, false),
            const SizedBox(height: 15),

            _buildTextField(_enrollmentController, "Enrollment Number (e.g. 01-134...)", Icons.badge_outlined, false),
            const SizedBox(height: 15),

            _buildTextField(_emailController, "University Email", Icons.email_outlined, false),
            const SizedBox(height: 15),

            _buildTextField(_passwordController, "Access Code (Password)", Icons.lock_outline_rounded, true),
            const SizedBox(height: 15),

            _buildTextField(_deptController, "Department", Icons.account_balance_rounded, false),
            const SizedBox(height: 15),

            _buildTextField(_semesterController, "Current Semester", Icons.school_outlined, false),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: Colors.cyanAccent.withOpacity(0.3),
                ),
                onPressed: () async {
                  if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                    // This call matches the 'signUp' signature in your AuthService
                    await _auth.signUp(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      _nameController.text.trim(),
                      _deptController.text.trim(),
                      _semesterController.text.trim(),
                      _enrollmentController.text.trim(),
                    );
                    if (mounted) Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in all identity fields"))
                    );
                  }
                },
                child: Text(
                    "INITIALIZE PROFILE",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1)
                ),
              ),
            ),
            const SizedBox(height: 40), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white10)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.cyanAccent)
        ),
      ),
    );
  }
}