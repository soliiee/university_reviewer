import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Home', style: GoogleFonts.cinzel())),
      body: Center(
        child: Text('Welcome, student!', style: GoogleFonts.lora(fontSize: 18, color: adduNavy)),
      ),
    );
  }
}
