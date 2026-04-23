import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      // Web-optimized popup sign-in
      final userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      final user = userCredential.user;
      final email = user?.email ?? '';

      if (!email.toLowerCase().endsWith('@addu.edu.ph')) {
        // Not an ADDU email — sign out and show error
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted to ADDU Gmail accounts.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Success — navigate to main home screen (replace current)
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width > 800 ? 480.0 : MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      backgroundColor: adduBackground,
      body: Center(
        child: Card(
          color: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: cardWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header / Logo placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: adduGold, borderRadius: BorderRadius.circular(8)),
                          child: Center(
                            child: Text('ADDU', style: GoogleFonts.lora(color: adduNavy, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('University Reviewer', style: GoogleFonts.lora(color: adduNavy, fontSize: 22, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Sign in with your Ateneo de Davao account to continue', style: GoogleFonts.roboto(color: Colors.black87)),
                  const SizedBox(height: 22),

                  // Sign-in button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: adduNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Text('G', style: GoogleFonts.roboto(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      label: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in with Google'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: adduNavy,
                      side: const BorderSide(color: adduGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                    onPressed: () {},
                    child: Text('Learn more', style: GoogleFonts.roboto(color: adduNavy)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
