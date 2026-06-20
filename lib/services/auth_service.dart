import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUp(
      String email,
      String password,
      String name,
      String dept,
      String semester,
      String enrollment
      ) async {
    try {
      // 1. Initialize the account in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      User? user = result.user;

      if (user != null) {
        // 2. Update the Auth profile display name immediately
        // This ensures user.displayName isn't null on the first load
        await user.updateDisplayName(name);

        // 3. Deploy the user document to the 'users' collection
        // We use .doc(user.uid).set() to ensure the Firestore ID
        // matches the Authentication UID perfectly.
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'department': dept,
          'semester': semester,
          'enrollment': enrollment,
          'email': email,
          'role': 'student', // Initial rank for the campus grid
          'createdAt': FieldValue.serverTimestamp(), // Native Firestore timestamp
        });

        print("Uplink Successful: Firestore profile created for ${user.uid}");
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Specifically catches issues like "email-already-in-use"
      print("AUTH TRANSMISSION ERROR: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      // Catches Firestore permission errors or network timeouts
      print("DATABASE TRANSMISSION ERROR: $e");
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } catch (e) {
      print("SIGN-IN ERROR: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}