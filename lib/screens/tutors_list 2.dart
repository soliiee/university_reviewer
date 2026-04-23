import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'tutor_details.dart';

class TutorsListScreen extends StatelessWidget {
  final String? subject;
  const TutorsListScreen({super.key, this.subject});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final Stream<QuerySnapshot> stream = subject != null
        ? fs.tutorsForSubjectStream(subject!, onlyVerified: true)
        : fs.tutorsStream();

    return Scaffold(
      appBar: AppBar(title: Text(subject != null ? 'Tutors: $subject' : 'Tutors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No tutors found'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? data['email'] ?? 'Tutor';
              final ratingRaw = data['rating_average'] ?? data['rating'] ?? data['rating_avg'];
              final rating = ratingRaw != null ? (double.tryParse(ratingRaw.toString()) ?? 0.0) : null;
              final verified = data['verified'] == true;
              final availability = data['availability'] ?? data['available'] ?? data['availability_times'];
              final availStr = _availabilityToString(availability);

              return ListTile(
                title: Text(name),
                subtitle: Text('Rating: ${rating != null ? rating.toStringAsFixed(1) : '-'}${availStr.isNotEmpty ? ' • Available: $availStr' : ''}'),
                trailing: verified ? const Icon(Icons.verified, color: Colors.green) : const Icon(Icons.warning, color: Colors.orange),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => TutorDetailsScreen(tutorId: d.id, initialData: data)));
                },
              );
            },
          );
        },
      ),
    );
  }
}

String _availabilityToString(dynamic availability) {
  if (availability == null) return '';
  if (availability is String) return availability;
  if (availability is List) return availability.map((e) => e.toString()).join(', ');
  if (availability is Map) return availability.entries.map((e) => '${e.key}: ${e.value}').join('; ');
  return availability.toString();
}
