import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  const AdminSidebar({super.key, required this.selectedIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Overview',
      'Tutor Verification',
      'Study Groups',
      'Subjects',
      'Reports',
      'Users',  // REMOVED 'Analytics'
    ];

    return Container(
      width: 260,
      color: const Color(0xFF003A8F),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFFFDB913), child: const Icon(Icons.school, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Ateneo Admin', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final selected = idx == selectedIndex;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Colors.white24,
                    leading: Icon(_iconForIndex(idx), color: Colors.white),
                    title: Text(items[idx], style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                    onTap: () => onItemSelected(idx),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('v0.1', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForIndex(int idx) {
    switch (idx) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.verified_user;
      case 2:
        return Icons.group;
      case 3:
        return Icons.book;
      case 4:
        return Icons.report;
      case 5:
        return Icons.people;
      default:
        return Icons.people;
    }
  }
}