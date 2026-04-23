import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TutorVerificationPage extends StatelessWidget {
  const TutorVerificationPage({super.key});

  Stream<QuerySnapshot> _tutorsStream() => FirebaseFirestore.instance.collection('tutors').snapshots();

  Future<void> _setVerified(String id, bool verified) async {
    await FirebaseFirestore.instance.collection('tutors').doc(id).update({'verified': verified});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tutor Verification', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _tutorsStream(),
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
                  final name = data['name'] ?? data['email'] ?? 'Untitled';
                  final subjects = (data['subjects'] as List?)?.cast<String>() ?? [];
                  final verified = data['verified'] == true;
                  final availability = data['availability'] ?? '';
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('Subjects: ${subjects.join(', ')}\nAvailability: $availability'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(verified ? 'Verified' : 'Unverified', style: TextStyle(color: verified ? Colors.green : Colors.red)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: verified ? null : () => _setVerified(d.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: !verified ? null : () => _setVerified(d.id, false),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
