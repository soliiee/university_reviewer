import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class TutorListWidget extends StatelessWidget {
  const TutorListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tutors').orderBy('averageRating', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No tutors found'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final d = docs[index].data();
            final name = (d['displayName'] as String?) ?? (d['name'] as String?) ?? docs[index].id;
            final photo = (d['photoUrl'] as String?) ?? (d['photo'] as String?);
            final isVerified = d['isVerified'] as bool? ?? false;
            final rating = (d['averageRating'] is num) ? (d['averageRating'] as num).toDouble() : 0.0;
            final subjects = (d['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(radius: 28, backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person) : null),
                title: Row(
                  children: [
                    Expanded(child: Text(name, style: GoogleFonts.lora(fontSize: 16, color: adduNavy))),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: adduGold, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.check, size: 12, color: Colors.white), const SizedBox(width: 6), Text('Verified', style: GoogleFonts.roboto(color: Colors.white, fontSize: 12))]),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.roboto(fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Subjects: ${subjects.join(', ')}', style: GoogleFonts.lora(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
