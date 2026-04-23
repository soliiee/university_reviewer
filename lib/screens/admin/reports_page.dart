import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildOverviewCards(context),
                  const SizedBox(height: 16),
                  _buildSessionStatusChart(context),
                  const SizedBox(height: 16),
                  _buildPopularSubjects(context),
                  const SizedBox(height: 16),
                  _buildRecentReports(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('sessions').get(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Sessions', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003A8F),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'tutor').get(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Tutors', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003A8F),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('study_groups').get(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Study Groups', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003A8F),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStatusChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Status Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No session data available'));
                }
                
                final docs = snap.data!.docs;
                int booked = 0, confirmed = 0, completed = 0, cancelled = 0;
                
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  switch (status) {
                    case 'booked': booked++; break;
                    case 'confirmed': confirmed++; break;
                    case 'completed': completed++; break;
                    case 'cancelled': cancelled++; break;
                  }
                }
                
                final total = docs.length;
                
                return Column(
                  children: [
                    _buildStatusRow('Booked', booked, Colors.orange, total),
                    const SizedBox(height: 8),
                    _buildStatusRow('Confirmed', confirmed, Colors.blue, total),
                    const SizedBox(height: 8),
                    _buildStatusRow('Completed', completed, Colors.green, total),
                    const SizedBox(height: 8),
                    _buildStatusRow('Cancelled', cancelled, Colors.red, total),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '$count sessions',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPopularSubjects(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popular Subjects',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No subject data available'));
                }
                
                // Count sessions per subject
                Map<String, int> subjectCounts = {};
                for (var doc in snap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final subject = (data['subject'] ?? 'Unknown').toString();
                  subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
                }
                
                // Sort by count
                final sortedSubjects = subjectCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                
                final topSubjects = sortedSubjects.take(5).toList();
                
                return Column(
                  children: topSubjects.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: entry.value / (topSubjects.first.value.toDouble()),
                                    backgroundColor: Colors.grey[200],
                                    color: const Color(0xFF003A8F),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent activity'));
                }
                
                final docs = snap.data!.docs;
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    final subject = data['subject'] ?? 'Unknown';
                    final status = data['status'] ?? 'pending';
                    final createdAt = data['createdAt'] as Timestamp?;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'completed' ? Colors.green : 
                                       (status == 'cancelled' ? Colors.red : 
                                       (status == 'confirmed' ? Colors.blue : Colors.orange)),
                        child: Icon(
                          status == 'completed' ? Icons.check : 
                          (status == 'cancelled' ? Icons.close : 
                          (status == 'confirmed' ? Icons.verified : Icons.schedule)),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(subject),
                      subtitle: Text('Status: ${status.toUpperCase()}'),
                      trailing: createdAt != null
                          ? Text(
                              _formatDate(createdAt.toDate()),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    
    if (difference.inDays > 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}