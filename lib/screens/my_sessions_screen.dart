import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';

class MySessionsScreen extends StatelessWidget {
  final String? userId;
  const MySessionsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text('Not signed in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.sessionsForUserStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No sessions found'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final subject = data['subject'] ?? 'Session';
              final scheduleRaw = data['schedule'];
              DateTime? scheduleDt;
              String scheduleLabel = '';
              try {
                if (scheduleRaw is Map && scheduleRaw['when'] is Timestamp) {
                  scheduleDt = (scheduleRaw['when'] as Timestamp).toDate();
                } else if (scheduleRaw is Map && scheduleRaw['when'] is String) {
                  scheduleLabel = scheduleRaw['when'];
                } else if (scheduleRaw is Timestamp) {
                  scheduleDt = scheduleRaw.toDate();
                } else if (scheduleRaw is String) {
                  scheduleLabel = scheduleRaw;
                }
              } catch (_) {}

              final status = (data['status'] ?? '').toString();
              final type = (data['type'] ?? 'tutor').toString();
              final createdAtRaw = data['createdAt'];
              DateTime? createdAt;
              if (createdAtRaw is Timestamp) createdAt = createdAtRaw.toDate();

              String timeRemaining = '';
              if (scheduleDt != null) {
                timeRemaining = _timeRemainingUntil(scheduleDt);
                scheduleLabel = _formatDateTime(scheduleDt);
              }
              final roomNumber = (data['roomNumber'] ?? data['room_number'] ?? '').toString();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(subject.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'booked' ? Colors.orange : (status == 'confirmed' ? Colors.green[600] : Colors.grey[400]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (scheduleLabel.isNotEmpty) Text('When: $scheduleLabel', style: const TextStyle(color: Colors.black87)),
                      if (roomNumber.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text('Room: $roomNumber', style: const TextStyle(color: Colors.black87)),
                      ),
                      if (timeRemaining.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(timeRemaining, style: const TextStyle(color: Colors.blueAccent)),
                      ),
                      const SizedBox(height: 8),
                      if (createdAt != null) Text('Created: ${_formatDateTime(createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'booked') ElevatedButton(
                            onPressed: () async {
                              try {
                                await fs.updateSessionStatus(d.id, 'cancelled');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session cancelled')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red));
                              }
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          // Delete button for study groups
                          if (type == 'study_group')
                            ElevatedButton(
                              onPressed: () async {
                                final groupId = (data['group_id'] ?? data['groupId'] ?? data['group'])?.toString();
                                final studentId = FirebaseAuth.instance.currentUser?.uid;
                                
                                if (groupId == null || studentId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Unable to delete: missing information'), backgroundColor: Colors.red)
                                  );
                                  return;
                                }
                                
                                // Show confirmation dialog
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Session'),
                                    content: const Text('Are you sure you want to delete this study group session? This will also remove you from the group.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed != true) return;
                                
                                try {
                                  await fs.removeStudyGroupMembershipAndSession(
                                    groupId: groupId, 
                                    studentId: studentId, 
                                    sessionId: d.id
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Session and membership removed'))
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red)
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final month = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    return '$month $day, $year • $hour:$minute $ampm';
  }

  String _timeRemainingUntil(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) {
      final ago = now.difference(dt);
      final days = ago.inDays;
      if (days > 0) return 'Started $days day(s) ago';
      final hours = ago.inHours;
      if (hours > 0) return 'Started $hours hour(s) ago';
      final mins = ago.inMinutes;
      return 'Started ${mins} minute(s) ago';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return 'In $days day(s) ${hours} hour(s)';
    if (hours > 0) return 'In $hours hour(s) ${minutes} minute(s)';
    return 'In $minutes minute(s)';
  }
}