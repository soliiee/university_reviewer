import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleChecker {
  /// Fetch role for [user] with debug prints.
  ///
  /// Returns the role string (trimmed, lowercased) or 'student' when missing.
  static Future<String> fetchRoleWithDebug(User user) async {
    try {
      print("=== ROLE CHECK START ===");
      print("UID from Auth: ${user.uid}");

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      print("Document exists: ${doc.exists}");
      print("Raw data: ${doc.data()}");

      if (!doc.exists) {
        // Default to 'student' when document is missing.
        print("User document NOT FOUND in Firestore — defaulting role to 'student'");
        print("ROLE: student");
        return 'student';
      }

      final data = doc.data();
      final dynamic roleRaw = data?['role'];
      final role = roleRaw == null ? 'student' : roleRaw.toString().trim().toLowerCase();

      print("Fetched role: $role");
      print("ROLE: $role");
      return role;
    } catch (e, st) {
      print("ERROR fetching role: $e");
      print(st);
      // On error, be permissive and treat as student (do not block non-admin users).
      print("ROLE: student (error fallback)");
      return 'student';
    }
  }
}

