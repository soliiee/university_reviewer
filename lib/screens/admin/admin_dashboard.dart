import 'package:flutter/material.dart';
import '../../widgets/admin_sidebar.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../my_account.dart';
import '../login_screen.dart';
import 'overview_page.dart';
import 'tutor_verification_page.dart';
import 'subjects_page.dart';
import 'study_groups_page.dart';
import 'users_page.dart';
import 'reports_page.dart';
// NO Analytics import here

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    OverviewPage(),
    TutorVerificationPage(),
    StudyGroupsPage(),
    SubjectsPage(),
    ReportsPage(),
    UsersPage(),
    // NO AnalyticsPage here
  ];

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(selectedIndex: _selectedIndex, onItemSelected: _onSelect),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))]),
                      child: Row(
                        children: [
                          Text('Admin Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.account_circle, color: Colors.white),
                            tooltip: 'My account',
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser;
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyAccountScreen(user: user)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Sign out',
                            onPressed: _logout,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _pages[_selectedIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }
}