import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

/// Minimal placeholder for legacy `AuthWrapper`.
/// The app now uses `main.dart`'s RootDecider. This file remains to avoid
/// breaking potential references but simply forwards to the login screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
