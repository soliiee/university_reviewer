import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class StudyGroupsPage extends StatelessWidget {
  StudyGroupsPage({super.key});

  Stream<QuerySnapshot> _groups() => FirebaseFirestore.instance.collection('study_groups').snapshots();
  final _fs = FirestoreService();

  Future<void> _addNewGroup(BuildContext context) async {
    final subjectCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final totalSlotsCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Add New Study Group'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Room Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalSlotsCtrl,
                    decoration: const InputDecoration(labelText: 'Total Slots *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text(selectedDate != null 
                                  ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                  : 'Select Date'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 8),
                                Text(selectedTime != null 
                                  ? selectedTime!.format(ctx)
                                  : 'Select Time'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  // Validate required fields
                  if (subjectCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a subject name'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  if (totalSlotsCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter total slots'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  final totalSlots = int.tryParse(totalSlotsCtrl.text.trim());
                  if (totalSlots == null || totalSlots <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number of slots'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  final newGroupData = {
                    'subjectName': subjectCtrl.text.trim(),
                    'roomNumber': roomCtrl.text.trim(),
                    'totalSlots': totalSlots,
                    'occupiedSlots': 0,
                    'description': descriptionCtrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  
                  if (selectedDate != null && selectedTime != null) {
                    final dateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    newGroupData['schedule'] = Timestamp.fromDate(dateTime);
                  }
                  
                  await FirebaseFirestore.instance.collection('study_groups').add(newGroupData);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Study group added successfully'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteGroup(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Group'),
        content: const Text('Are you sure you want to delete this study group? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('study_groups').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Study group deleted')));
      }
    }
  }

  Future<void> _editGroup(BuildContext context, String id, Map<String, dynamic> currentData) async {
    final subjectCtrl = TextEditingController(text: currentData['subjectName'] ?? currentData['subject_name'] ?? currentData['subject'] ?? '');
    final roomCtrl = TextEditingController(text: currentData['roomNumber'] ?? currentData['room_number'] ?? '');
    final totalSlotsCtrl = TextEditingController(text: (currentData['totalSlots'] ?? currentData['total_slots'] ?? currentData['slots'] ?? 0).toString());
    final descriptionCtrl = TextEditingController(text: currentData['description'] ?? '');
    
    DateTime? scheduleDt;
    final scheduleRaw = currentData['schedule'];
    if (scheduleRaw is Timestamp) {
      scheduleDt = scheduleRaw.toDate();
    } else if (scheduleRaw is DateTime) {
      scheduleDt = scheduleRaw;
    }
    
    DateTime? selectedDate = scheduleDt;
    TimeOfDay? selectedTime = scheduleDt != null ? TimeOfDay.fromDateTime(scheduleDt) : null;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Edit Study Group'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Room Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totalSlotsCtrl,
                    decoration: const InputDecoration(labelText: 'Total Slots', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text(selectedDate != null 
                                  ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                  : 'Select Date'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 8),
                                Text(selectedTime != null 
                                  ? selectedTime!.format(ctx)
                                  : 'Select Time'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final updatedData = {
                    'subjectName': subjectCtrl.text.trim(),
                    'roomNumber': roomCtrl.text.trim(),
                    'totalSlots': int.tryParse(totalSlotsCtrl.text.trim()) ?? 0,
                    'description': descriptionCtrl.text.trim(),
                  };
                  
                  if (selectedDate != null && selectedTime != null) {
                    final dateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    updatedData['schedule'] = Timestamp.fromDate(dateTime);
                  }
                  
                  await FirebaseFirestore.instance.collection('study_groups').doc(id).update(updatedData);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Study group updated')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewDetails(BuildContext context, Map<String, dynamic> data) {
    final subject = (data['subjectName'] ?? data['subject_name'] ?? data['subject'] ?? 'Unknown').toString();
    final room = (data['roomNumber'] ?? data['room_number'] ?? 'Not specified').toString();
    final totalSlots = (data['totalSlots'] ?? data['total_slots'] ?? data['slots'] ?? 0);
    final occupiedSlots = (data['occupiedSlots'] ?? data['occupied_slots'] ?? data['occupied'] ?? 0);
    final description = data['description'] ?? 'No description provided';
    
    String scheduleStr = 'Not scheduled';
    final scheduleRaw = data['schedule'];
    if (scheduleRaw is Timestamp) {
      final dt = scheduleRaw.toDate();
      scheduleStr = '${dt.year}-${dt.month}-${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (scheduleRaw is DateTime) {
      final dt = scheduleRaw;
      scheduleStr = '${dt.year}-${dt.month}-${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.meeting_room, 'Room', room),
            const SizedBox(height: 8),
            _detailRow(Icons.calendar_today, 'Schedule', scheduleStr),
            const SizedBox(height: 8),
            _detailRow(Icons.people, 'Slots', '$occupiedSlots / $totalSlots'),
            const SizedBox(height: 8),
            _detailRow(Icons.description, 'Description', description.isEmpty ? 'No description' : description),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSchedule(DateTime dt) {
    return '${dt.year}-${dt.month}-${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Study Groups', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton.icon(
          onPressed: () => _addNewGroup(context),
          icon: const Icon(Icons.add),
          label: const Text('Add New Study Group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003A8F),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Starting migration...')));
            try {
              await _fs.migrateAddRoomNumber(defaultValue: 'TBD');
              if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('Migration complete')));
            } catch (e) {
              if (context.mounted) messenger.showSnackBar(SnackBar(content: Text('Migration failed: ${e.toString()}')));
            }
          },
          child: const Text('Populate roomNumber (TBD)'),
        ),
      ]),
      const SizedBox(height: 12),
      Expanded(child: StreamBuilder<QuerySnapshot>(stream: _groups(), builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No study groups')); 
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final subject = (data['subjectName'] ?? data['subject_name'] ?? data['subject'] ?? 'Unknown').toString();
              final room = (data['roomNumber'] ?? data['room_number'] ?? '').toString();
              final scheduleRaw = data['schedule'];
              String scheduleStr = '';
              try {
                if (scheduleRaw is Timestamp) {
                  final dt = scheduleRaw.toDate();
                  scheduleStr = _formatSchedule(dt);
                } else if (scheduleRaw is DateTime) {
                  scheduleStr = _formatSchedule(scheduleRaw);
                } else if (scheduleRaw != null) {
                  scheduleStr = scheduleRaw.toString();
                }
              } catch (_) {
                scheduleStr = scheduleRaw?.toString() ?? '';
              }

              int total = 0;
              int occupied = 0;
              final totalRaw = data['totalSlots'] ?? data['total_slots'] ?? data['slots'];
              final occupiedRaw = data['occupiedSlots'] ?? data['occupied_slots'] ?? data['occupied'] ?? 0;
              if (totalRaw is int) total = totalRaw;
              else if (totalRaw is double) total = totalRaw.toInt();
              else if (totalRaw is String) total = int.tryParse(totalRaw) ?? 0;

              if (occupiedRaw is int) occupied = occupiedRaw;
              else if (occupiedRaw is double) occupied = occupiedRaw.toInt();
              else if (occupiedRaw is String) occupied = int.tryParse(occupiedRaw) ?? 0;

              final slotsStr = '$occupied / $total';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(subject),
                  subtitle: Text('Schedule: $scheduleStr${room.isNotEmpty ? ' | Room: $room' : ''} | Slots: $slotsStr'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _viewDetails(context, data),
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editGroup(context, d.id, data),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGroup(context, d.id),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
      }))
    ]);
  }
}