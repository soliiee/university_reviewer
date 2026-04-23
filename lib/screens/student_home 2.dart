import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
// Search and Firestore interactions are handled in dedicated pages/services.
import 'login_screen.dart';
import 'my_account.dart';
import 'tutors_list.dart';
import 'study_groups_screen.dart';
import '../pages/search_page.dart';
import 'my_sessions_screen.dart';

/// StudentHomeScreen
///
/// Contains welcome header, subject search, tutor listings (verified only), booking flow,
/// and quick access to study groups and sessions.
class StudentHomeScreen extends StatefulWidget {
  final User? user;
  const StudentHomeScreen({super.key, this.user});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

// Lightweight wrapper for subject search results (supports demo items without Firestore types)
class _SubjectResult {
  final String id;
  final Map<String, dynamic> data;
  _SubjectResult({required this.id, required this.data});
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _searchCtrl = TextEditingController();
  // FirestoreService instance removed; searches are now handled on the SearchPage.
  // Use a small lightweight wrapper so we can show demo items without Firestore types
  List<_SubjectResult>? _subjectResults;

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  // Note: searching is handled on the dedicated SearchPage now. Keep a local
  // _subjectResults list for the inline quick-search UI if we later re-enable
  // local search behavior.

  // Booking is handled in the Tutor Details screen now.

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user?.displayName ?? widget.user?.email ?? 'Student';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My account',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyAccountScreen(user: widget.user)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Welcome, $displayName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Search bar
            Row(children: [
              Expanded(child: TextField(controller: _searchCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search subjects (e.g., calculus, chemistry)'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Open the dedicated Search page and pass the current query so it shows
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchPage(initialQuery: _searchCtrl.text.trim())));
                },
                child: const Text('Search'),
              )
            ]),
            const SizedBox(height: 12),

            // Search results: subjects or default quick cards
            if (_subjectResults != null) ...[
              Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _subjectResults!.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final d = _subjectResults![idx];
                    final data = d.data;
                    final name = data['name'] ?? '<unnamed>';
                    return ListTile(
                      title: Text(name),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TutorsListScreen(subject: name.toString()))),
                        child: const Text('Find tutors'),
                      ),
                    );
                  },
                ),
              )
            ] else ...[
              // Quick cards when no search
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 4,
                  mainAxisSpacing: 12,
                  children: [
                    _buildCard(context, Icons.person_search, 'Find Tutors', 'Browse tutors and schedules', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TutorsListScreen()));
                    }),
                    _buildCard(context, Icons.group, 'Join Study Groups', 'Find or create study groups', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudyGroupsScreen()));
                    }),
                    _buildCard(context, Icons.calendar_today, 'My Sessions', 'View upcoming sessions', onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MySessionsScreen(userId: widget.user?.uid)));
                    }),
                  ],
                ),
              )
            ],
            
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFDB913),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
