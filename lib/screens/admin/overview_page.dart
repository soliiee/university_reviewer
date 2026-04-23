import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  Future<int> _count(String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return snap.docs.length;
  }

  Widget _buildCard(BuildContext context, String title, Future<int> futureCount, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(width: 8, height: 48, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: futureCount,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Text('Loading...');
                      return Text('${snap.data ?? 0}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold));
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deepBlue = const Color(0xFF003A8F);
    final gold = const Color(0xFFFDB913);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.5,
          children: [
            _buildCard(context, 'Total Users', _count('users'), deepBlue),
            _buildCard(context, 'Verified Tutors', _count('tutors'), gold),
            _buildCard(context, 'Unverified Tutors', _count('tutors'), Colors.orange),
            _buildCard(context, 'Active Study Groups', _count('study_groups'), Colors.teal),
            _buildCard(context, 'Total Sessions', _count('sessions'), Colors.purple),
          ],
        ),
      ],
    );
  }
}
