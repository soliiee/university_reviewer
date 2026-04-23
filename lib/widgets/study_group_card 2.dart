import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class StudyGroupCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const StudyGroupCard({super.key, required this.doc});

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchTutor(String uid) {
    return FirebaseFirestore.instance.collection('tutors').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final subject = (data['subjectName'] as String?) ?? '';
    final scheduleTs = data['schedule'];
    DateTime schedule = DateTime.now();
    if (scheduleTs is Timestamp) schedule = scheduleTs.toDate();
    final assignedTutorId = data['assigned_tutor_id'] as String?;
    final imageUrl = data['imageUrl'] as String?;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 8),
            Text(subject, style: GoogleFonts.lora(fontSize: 18, color: adduNavy, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('When: ${schedule.toLocal()}', style: GoogleFonts.roboto(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Led by: ', style: TextStyle(fontWeight: FontWeight.w600)),
                if (assignedTutorId == null) Text('TBA', style: GoogleFonts.lora()),
                if (assignedTutorId != null)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: _fetchTutor(assignedTutorId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                      if (!snapshot.hasData || !snapshot.data!.exists) return Text('Unknown', style: GoogleFonts.lora());
                      final t = snapshot.data!;
                      final td = t.data() ?? {};
                      final name = (td['displayName'] as String?) ?? (td['name'] as String?) ?? t.id;
                      final photo = (td['photoUrl'] as String?) ?? (td['photo'] as String?);
                      return Row(
                        children: [
                          if (photo != null)
                            CircleAvatar(radius: 18, backgroundImage: NetworkImage(photo))
                          else
                            const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                          const SizedBox(width: 8),
                          Text(name, style: GoogleFonts.lora(fontSize: 14, color: adduNavy)),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
