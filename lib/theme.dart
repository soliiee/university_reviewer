import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ADDU Brand Colors
const Color adduNavy = Color(0xFF003366);
const Color adduGold = Color(0xFFC9A050);
const Color adduBackground = Color(0xFFF5F7FA);
const Color adduError = Color(0xFFB00020);
const Color adduSecondaryBlue = Color(0xFF9BD7ED);

final ThemeData adduTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: adduNavy, primary: adduNavy, secondary: adduGold, error: adduError),
  scaffoldBackgroundColor: adduBackground,
  useMaterial3: false,
  primaryColor: adduNavy,
  // error color is provided via colorScheme
  appBarTheme: AppBarTheme(
    backgroundColor: adduNavy,
    elevation: 0,
    titleTextStyle: GoogleFonts.lora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
    toolbarTextStyle: GoogleFonts.lora(color: Colors.white, fontSize: 18),
    surfaceTintColor: adduNavy,
    // We'll add a bottom border by using bottom property in AppBar widget where needed.
  ),
  // Use Cinzel for headings and Lora for body to match ADDU identity
  textTheme: TextTheme(
    displayLarge: GoogleFonts.cinzel(color: adduNavy, fontSize: 34, fontWeight: FontWeight.w700),
    displayMedium: GoogleFonts.cinzel(color: adduNavy, fontSize: 24, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.lora(color: Colors.black87, fontSize: 16),
    bodyMedium: GoogleFonts.lora(color: Colors.black87, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: adduNavy,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 2,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: adduGold,
      side: const BorderSide(color: adduGold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  // Card styling (use Card widgets with these defaults if needed)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.grey)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.grey)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: adduNavy, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: adduError)),
    hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
  ),
  cardColor: Colors.white,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: adduNavy),
);
