import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: adduNavy,
        border: Border(bottom: BorderSide(color: adduGold, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: adduGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('ADDU', style: GoogleFonts.lora(color: adduNavy, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Ateneo de Davao - University Reviewer', style: GoogleFonts.lora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            // Optional actions / account menu
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'signout') {
                  await AuthService().signOut();
                }
                // other menu items can be added here
              },
              color: adduNavy,
              icon: const Icon(Icons.account_circle, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'signout', child: Text('Sign out', style: TextStyle(color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
