import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

String _availabilityToString(dynamic availability) {
  if (availability == null) return '';
  if (availability is String) return availability;
  if (availability is List) return availability.map((e) => e.toString()).join(', ');
  if (availability is Map) return availability.entries.map((e) => '${e.key}: ${e.value}').join('; ');
  return availability.toString();
}

class TutorDetailsScreen extends StatelessWidget {
  final String tutorId;
  final Map<String, dynamic>? initialData;
  const TutorDetailsScreen({super.key, required this.tutorId, this.initialData});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    // If we already have initialData, show it immediately; otherwise fetch the tutor doc.
    Widget buildFromData(Map<String, dynamic> data) {
      final name = data['name'] ?? data['email'] ?? 'Tutor';
      final bio = data['bio'] ?? '';
      final subjects = (data['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  final rating = data['rating_average']?.toString() ?? '-';
      final availability = data['availability'] ?? data['available'] ?? data['availability_times'];
      final availStr = _availabilityToString(availability);

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Rating: $rating'),
            if (availStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Availability: $availStr'),
            ],
            const SizedBox(height: 12),
            if (subjects.isNotEmpty) Wrap(spacing: 8, children: subjects.map((s) => Chip(label: Text(s))).toList()),
            const SizedBox(height: 12),
            if (bio.toString().isNotEmpty) Text(bio),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date == null) return;
                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
                if (time == null) return;
                final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                final schedule = {'when': dt.toIso8601String()};
                try {
                  final studentId = FirebaseAuth.instance.currentUser?.uid;
                  if (studentId == null) throw Exception('Sign in first');
                  await fs.bookSession(tutorId: tutorId, studentId: studentId, subject: subjects.isNotEmpty ? subjects.first : 'General', schedule: schedule);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session booked')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Book Session'),
            )
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tutor details')),
      body: initialData != null
          ? buildFromData(initialData!)
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('tutors').doc(tutorId).get(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Tutor not found'));
                final data = snap.data!.data() as Map<String, dynamic>;
                return buildFromData(data);
              },
            ),
    );
  }
}
