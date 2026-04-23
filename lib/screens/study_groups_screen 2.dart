import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  final FirestoreService _fs = FirestoreService();
  final Set<String> _joining = {}; // track group ids currently being joined to prevent duplicate taps

  @override
  Widget build(BuildContext context) {
    final fs = _fs;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Groups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.studyGroupsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No study groups yet'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final subjectName = data['subjectName'] ?? data['subject_name'] ?? data['name'] ?? 'Group';
              final totalSlots = (data['totalSlots'] ?? data['total_slots'] ?? data['slots'] ?? 0) as int? ?? (data['slots'] is int ? data['slots'] as int : 0);
              final occupiedSlots = (data['occupiedSlots'] ?? data['occupied_slots'] ?? 0) as int? ?? 0;
              // schedule may be a Firestore Timestamp or a stored ISO string
              final rawSchedule = data['schedule'];
              final scheduleStr = _formatTimestamp(rawSchedule) ?? 'TBD';
              final remaining = (totalSlots - occupiedSlots).clamp(0, totalSlots);

              return ListTile(
                title: Text(subjectName),
                subtitle: Text('Schedule: $scheduleStr • $occupiedSlots/$totalSlots occupied'),
                onTap: () {
                  // Show details dialog with createdAt, createdBy, description
                  final createdAtRaw = data['createdAt'] ?? data['created_at'];
                  final createdAtStr = _formatTimestamp(createdAtRaw) ?? 'Unknown';
                  final createdBy = data['createdBy'] ?? data['created_by'] ?? data['created_by_name'] ?? 'Unknown';
                  final description = (data['description'] ?? '') as String;
                  final imageUrl = data['imageUrl'] ?? data['image_url'];
                  final roomNumber = data['roomNumber'] ?? data['room_number'] ?? '';

                  // Schedule dialog to run after this frame to avoid pointer/mouse-tracker
                  // assertions that can happen when adding overlays during pointer handling.
                  Future.microtask(() {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(subjectName),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 150,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (ctx, child, chunk) {
                                        if (chunk == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                ),
                              Text('Created by: $createdBy', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Created at: $createdAtStr'),
                              const SizedBox(height: 12),
                              if (description.isNotEmpty) ...[
                                const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(description),
                                const SizedBox(height: 8),
                              ],
                              Text('Slots: $occupiedSlots / $totalSlots (remaining: $remaining)'),
                              const SizedBox(height: 6),
                              if (roomNumber != null && roomNumber.toString().isNotEmpty) Text('Room: ${roomNumber.toString()}'),
                              const SizedBox(height: 6),
                              Text('Schedule: $scheduleStr'),
                            ],
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                      ),
                    );
                  });
                },
                trailing: FutureBuilder<bool>(
                  future: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final uid = user?.uid;
                    if (uid == null) return false;
                    return await fs.isMember(d.id, uid);
                  }(),
                  builder: (context, snapMember) {
                    final joined = snapMember.data ?? false;
                    if (snapMember.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 80, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
                    }
                    if (joined) {
                      return ElevatedButton(onPressed: null, child: const Text('Joined'));
                    }

                    final isJoining = _joining.contains(d.id);
                    return ElevatedButton(
                      onPressed: isJoining
                          ? null
                          : () async {
                              setState(() => _joining.add(d.id));
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                final userId = user?.uid;
                                if (userId == null) throw Exception('Sign in first');

                                // Attempt to fetch user profile from users/{uid}
                                final userDoc = await fs.getUserDoc(userId);
                                final profile = userDoc.exists ? (userDoc.data() as Map<String, dynamic>? ?? {}) : {};

                                final member = {
                                  'uid': userId,
                                  'name': profile['name'] ?? user?.displayName ?? '',
                                  'email': profile['email'] ?? user?.email ?? '',
                                  'joinedAt': FieldValue.serverTimestamp(),
                                };

                                await fs.joinStudyGroupWithMember(d.id, member);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group')));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join: ${e.toString()}'), backgroundColor: Colors.red));
                              } finally {
                                if (mounted) setState(() => _joining.remove(d.id));
                              }
                            },
                      child: isJoining
                          ? const SizedBox(width: 80, height: 18, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                          : const Text('Join'),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String? _formatTimestamp(dynamic t) {
  if (t == null) return null;
  if (t is Timestamp) {
    final dt = t.toDate().toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
  if (t is DateTime) {
    final dt = t.toLocal();
    return dt.toIso8601String();
  }
  if (t is String) return t;
  return t.toString();
}
