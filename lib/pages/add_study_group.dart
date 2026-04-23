import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class AddStudyGroupPage extends StatefulWidget {
  const AddStudyGroupPage({super.key});

  @override
  State<AddStudyGroupPage> createState() => _AddStudyGroupPageState();
}

class _AddStudyGroupPageState extends State<AddStudyGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _slotsController = TextEditingController(text: '5');
  final _roomController = TextEditingController();

  DateTime? _schedule;
  String? _selectedSubject;
  String? _assignedTutorId;

  static const List<String> subjects = [
    'IT 321 - Software Engineering',
    'Theo 141 - Theology',
    'Math 101 - Calculus I',
    'CS 201 - Data Structures',
    'Eng 110 - Academic Writing',
    'Phys 120 - Physics',
    'Chem 101 - General Chemistry',
    'Hist 100 - Philippine History',
    'Bio 130 - General Biology',
    'Econ 101 - Principles of Economics'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _slotsController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 18, minute: 0));
    if (time == null) return;
    setState(() {
      _schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createStudyGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }
    if (_schedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a schedule')));
      return;
    }

    final int slots = int.tryParse(_slotsController.text) ?? 1;
    final user = FirebaseAuth.instance.currentUser;
    final createdBy = user?.displayName ?? user?.email ?? 'Unknown';

    final doc = {
      'subjectName': _selectedSubject,
      'description': _descriptionController.text.trim(),
      'schedule': Timestamp.fromDate(_schedule!),
      'totalSlots': slots,
      'occupiedSlots': 0,
      'imageUrl': _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
      'assigned_tutor_id': _assignedTutorId,
      'roomNumber': _roomController.text.trim(),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await FirebaseFirestore.instance.collection('study_groups').add(doc);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Study group created')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Study Group', style: GoogleFonts.lora())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add Study Group', style: GoogleFonts.lora(fontSize: 22, color: adduNavy)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedSubject = v),
                        validator: (v) => v == null ? 'Please choose a subject' : null,
                      ),
                      const SizedBox(height: 12),
                      // Tutor assignment dropdown (loads tutors from Firestore)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('tutors').orderBy('name').snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: _assignedTutorId,
                            decoration: const InputDecoration(labelText: 'Assign Tutor (optional)'),
                            items: docs.map((d) {
                              final data = d.data();
                              final display = (data['displayName'] as String?) ?? (data['name'] as String?) ?? d.id;
                              return DropdownMenuItem(value: d.id, child: Text(display));
                            }).toList(),
                            onChanged: (v) => setState(() => _assignedTutorId = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        minLines: 2,
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a description' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_schedule == null ? 'No schedule chosen' : 'Scheduled: ${_schedule!.toLocal()}'),
                          ),
                          TextButton(
                            onPressed: _pickDateTime,
                            child: const Text('Pick Date & Time'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _slotsController,
                        decoration: const InputDecoration(labelText: 'Slots'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a positive number of slots';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                        keyboardType: TextInputType.url,
                      ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: 'Room Number (e.g. Rm 201)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a room number' : null,
            ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _createStudyGroup,
                        style: ElevatedButton.styleFrom(backgroundColor: adduNavy),
                        child: const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Text('Create')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
