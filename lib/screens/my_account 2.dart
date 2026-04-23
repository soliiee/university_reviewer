import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

String _prettifyKey(String key) {
  // convert snake_case or camelCase to Title Case
  final replaced = key.replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}').replaceAll('_', ' ');
  return replaced.split(' ').map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
}

class MyAccountScreen extends StatelessWidget {
  final User? user;
  const MyAccountScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid;
    final displayName = user?.displayName ?? '';
    final email = user?.email ?? '';
    final photo = user?.photoURL;
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person, size: 48) : null,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot?>(
              future: uid != null ? fs.getUserDoc(uid) : Future.value(null),
              builder: (context, nameSnap) {
                String shownName = displayName;
                if (nameSnap.connectionState == ConnectionState.done && nameSnap.hasData && nameSnap.data!.exists) {
                  final map = nameSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final docName = (map['name'] ?? map['fullName'] ?? '').toString();
                  if (docName.isNotEmpty) shownName = docName;
                }
                return Center(child: Text(shownName.isNotEmpty ? shownName : 'No display name', style: Theme.of(context).textTheme.titleLarge));
              },
            ),
            const SizedBox(height: 4),
            Center(child: Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54))),
            const SizedBox(height: 24),

            const Text('Account details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Load additional fields from users/{uid}
            if (uid == null) 
              const Text('Not signed in') 
            else 
              FutureBuilder<DocumentSnapshot>(
                future: fs.getUserDoc(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snap.hasData || !snap.data!.exists) {
                    return const Text('No user profile data found.');
                  }
                  final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                  final role = (data['role'] ?? 'student').toString();

                  // friendly joined date
                  final joinedRaw = data['createdAt'] ?? data['joinedAt'] ?? data['joined'] ?? data['created_at'];
                  String joined = 'Unknown';
                  try {
                    if (joinedRaw is Timestamp) {
                      final dt = joinedRaw.toDate();
                      joined = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
                    } else if (joinedRaw is String) {
                      joined = joinedRaw;
                    }
                  } catch (_) {}

                  // Build a list of tiles from all document fields (except the uid)
                  final fieldKeys = data.keys.toList()..sort();
                  // remove fields we display separately
                  fieldKeys.removeWhere((k) => k == 'role' || k == 'createdAt' || k == 'created_at' || k == 'joinedAt' || k == 'joined' || k == 'phone');

                  List<Widget> fieldWidgets = [];
                  for (final key in fieldKeys) {
                    final val = data[key];
                    Widget subtitle;
                    if (val == null) {
                      subtitle = const Text('—');
                    } else if (val is Timestamp) {
                      final dt = val.toDate();
                      subtitle = Text('${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}');
                    } else if (val is List) {
                      subtitle = Wrap(spacing: 8, runSpacing: 6, children: val.map<Widget>((e) => Chip(label: Text(e.toString()))).toList());
                    } else if (val is Map) {
                      final pretty = const JsonEncoder.withIndent('  ').convert(val);
                      subtitle = Text(pretty);
                    } else {
                      subtitle = Text(val.toString());
                    }

                    fieldWidgets.add(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_prettifyKey(key)),
                          subtitle: subtitle,
                        ),
                        const Divider(),
                      ],
                    ));
                  }

                  final phone = (data['phone'] ?? '').toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Role'),
                        subtitle: Text(role),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Member since'),
                        subtitle: Text(joined),
                      ),
                      if (phone.isNotEmpty) ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone),
                        title: const Text('Phone'),
                        subtitle: Text(phone),
                      ),
                      const SizedBox(height: 8),
                      // Dynamic fields from the document
                      ...fieldWidgets,
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          await AuthService().signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        },
                      )
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
