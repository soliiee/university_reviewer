import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  Stream<QuerySnapshot> _users() => FirebaseFirestore.instance
      .collection('users')
      .snapshots();

  Future<void> _setRole(String id, String role) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({'role': role});
    } catch (e) {
      debugPrint('Error updating role: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _users(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error: ${snap.error}'),
                      ],
                    ),
                  );
                }
                
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final d = docs[idx];
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final email = data['email'] ?? '<no email>';
                    final rawRole = (data['role'] ?? 'student').toString().toLowerCase().trim();
                    
                    // Map any role variation to valid values
                    String validRole = 'student';
                    if (rawRole == 'admin' || rawRole == 'administrator') {
                      validRole = 'admin';
                    } else if (rawRole == 'tutor') {
                      validRole = 'tutor';
                    } else {
                      validRole = 'student';
                    }
                    
                    return ListTile(
                      title: Text(email),
                      subtitle: Text('Role: ${validRole[0].toUpperCase() + validRole.substring(1)}'),
                      trailing: DropdownButton<String>(
                        value: validRole,
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                          DropdownMenuItem(value: 'tutor', child: Text('Tutor')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (v) {
                          if (v != null && v != validRole) {
                            _setRole(d.id, v).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Role updated to $v')),
                              );
                            }).catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                              );
                            });
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}