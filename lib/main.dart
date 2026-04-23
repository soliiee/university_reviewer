import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/student_home.dart';
import 'utils/role_checker.dart';
//Sol Lumantas
/// Minimal app focused only on authentication and admin-checking.
/// - Initializes Firebase
/// - Shows a simple auth-aware home that routes to the login screen
///   or the admin dashboard depending on the user's role.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UniReviewerApp());
}

class UniReviewerApp extends StatelessWidget {
  const UniReviewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ateneo Reviewer',
      debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF003A8F), // Deep Blue
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003A8F),
            primary: const Color(0xFF003A8F),
            secondary: const Color(0xFFFDB913),
            background: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF003A8F),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003A8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFDB913),
              side: const BorderSide(color: Color(0xFFFDB913)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      home: const RootDecider(),
    );
  }
}

class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    // Listen for auth changes and rebuild accordingly
    FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    print('RootDecider: currentUser uid=${user?.uid} email=${user?.email}');
    if (user == null) return const LoginScreen();

    // If user is signed-in, fetch the role and show corresponding screen.
    return FutureBuilder<String>(
      future: RoleChecker.fetchRoleWithDebug(user),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final role = snap.data ?? 'student';
        if (role.toLowerCase().trim() == 'admin') return const AdminDashboard();
        return StudentHomeScreen(user: user);
      },
    );
  }
}
