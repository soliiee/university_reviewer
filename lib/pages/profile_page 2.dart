import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _joinedGroupsStream(String uid) {
    return FirebaseFirestore.instance.collection('study_groups').where('members', arrayContains: uid).orderBy('schedule').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Account', style: GoogleFonts.cinzel())),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Account', style: GoogleFonts.cinzel())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 36, backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null, child: user.photoURL == null ? const Icon(Icons.account_circle, size: 48) : null),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName ?? 'No name', style: GoogleFonts.cinzel(fontSize: 18, color: adduNavy)),
                          const SizedBox(height: 6),
                          Text(user.email ?? '', style: GoogleFonts.lora()),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('My Joined Groups', style: GoogleFonts.cinzel(fontSize: 18, color: adduNavy)),
              const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _joinedGroupsStream(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const Text('You have not joined any groups yet');
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final subject = (data['subjectName'] as String?) ?? '';
                      final schedTs = data['schedule'];
                      DateTime schedule = DateTime.now();
                      if (schedTs is Timestamp) schedule = schedTs.toDate();
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: ListTile(
                          title: Text(subject, style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                          subtitle: Text('When: ${schedule.toLocal()}', style: GoogleFonts.roboto(fontSize: 12)),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
