import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../utils/role_checker.dart';
import 'admin/admin_dashboard.dart';
import 'student_home.dart';

/// Simple, beginner-friendly login screen with Email/Password and Google Sign-In.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithEmail(email: _emailController.text, password: _passwordController.text);
  final user = FirebaseAuth.instance.currentUser ?? cred.user;
  if (user == null) throw Exception('No user returned from authentication');

  // Debug prints for verification
  print('UID: ${user.uid}');
  print('Email: ${user.email}');
  print('LoginScreen: signed in UID=${user.uid} email=${user.email}');
      // Strict debug flow: fetch role, wait for it, then decide navigation.
      final role = await RoleChecker.fetchRoleWithDebug(user);
      if (!mounted) return;
      print('ROLE: $role');
      if (role.toString().trim().toLowerCase() == 'admin') {
        print('ADMIN ACCESS GRANTED');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        print('STUDENT ACCESS - redirecting to StudentHome');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StudentHomeScreen(user: user)));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Authentication error'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithGoogle();
  final user = FirebaseAuth.instance.currentUser ?? cred.user;
  if (user == null) throw Exception('No user returned from Google Sign-In');

  // Debug prints for verification
  print('UID: ${user.uid}');
  print('Email: ${user.email}');
  print('LoginScreen: signed in (google) UID=${user.uid} email=${user.email}');
      // Strict debug flow: fetch role, wait for it, then decide navigation.
      final role = await RoleChecker.fetchRoleWithDebug(user);
      if (!mounted) return;
      print('ROLE: $role');
      if (role.toString().trim().toLowerCase() == 'admin') {
        print('ADMIN ACCESS GRANTED');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        print('STUDENT ACCESS - redirecting to StudentHome');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StudentHomeScreen(user: user)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text('Ateneo Reviewer', style: theme.textTheme.headlineSmall?.copyWith(color: const Color(0xFF003A8F), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Peer Tutoring & Study Groups', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
              const SizedBox(height: 20),

              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 420,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6) ? 'Enter at least 6 characters' : null,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _loginWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003A8F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: _loading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Login with Email'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.login, color: Color(0xFFFDB913)),
                              label: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in with Google', style: TextStyle(color: Color(0xFFFDB913))),
                              onPressed: _loading ? null : _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFDB913)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forgot password? Use Firebase console for this demo.'))),
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
