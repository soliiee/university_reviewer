import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Minimal AuthService with Email/Password and Google Sign-In support.
/// - Uses FirebaseAuth for auth operations.
/// - On web, uses `signInWithPopup`; on mobile, uses `google_sign_in` package.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed in user, if any.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email & password.
  /// Throws [FirebaseAuthException] on common auth errors.
  Future<UserCredential> signInWithEmail({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// Sign in with Google. Handles web and mobile flows.
  /// Throws exceptions on failure.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Use popup for web. Popup blockers are common in browsers; we
      // catch common web errors and rethrow with a clearer message so the
      // UI can show actionable text.
      final provider = GoogleAuthProvider();
      try {
        return await _auth.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        // Convert some common web errors to friendlier messages.
        final code = e.code;
        if (code == 'popup-blocked' || code == 'auth/popup-blocked') {
          throw FirebaseAuthException(code: e.code, message: 'Popup blocked by browser. Please allow popups or try a different browser.');
        }
        if (code == 'popup-closed-by-user' || code == 'auth/popup-closed-by-user') {
          throw FirebaseAuthException(code: e.code, message: 'Popup closed before completing sign-in. Please try again.');
        }
        // Re-throw other FirebaseAuthExceptions so callers can handle them.
        rethrow;
      } catch (e) {
        // Non-Firebase exceptions (network, etc.)
        throw Exception('Google sign-in failed (web): ${e.toString()}');
      }
    } else {
      // Mobile (Android/iOS) flow using google_sign_in package
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in aborted');
      final GoogleSignInAuthentication auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken);
      return await _auth.signInWithCredential(credential);
    }
  }

  /// Sign out from Firebase and also from GoogleSignIn (if used on mobile).
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } finally {
      await _auth.signOut();
    }
  }
}
