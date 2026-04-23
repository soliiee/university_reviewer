import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/firestore_service.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _scheduleFilter = 'Any';
  static const scheduleOptions = ['Any', 'MW', 'TTh', 'F'];

  bool _matchesSchedule(DateTime dt, String scheduleFilter) {
    if (scheduleFilter == 'Any') return true;
    final weekday = dt.weekday; // 1 = Monday ... 7 = Sunday
    if (scheduleFilter == 'MW') return weekday == DateTime.monday || weekday == DateTime.wednesday;
    if (scheduleFilter == 'TTh') return weekday == DateTime.tuesday || weekday == DateTime.thursday;
    if (scheduleFilter == 'F') return weekday == DateTime.friday;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _query = widget.initialQuery!.trim();
    }
  }
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('study_groups').orderBy('schedule').snapshots();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Search Study Groups', style: GoogleFonts.cinzel()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Search subjects or description', prefixIcon: const Icon(Icons.search)),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _scheduleFilter,
                    items: scheduleOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _scheduleFilter = v ?? 'Any'),
                    decoration: const InputDecoration(labelText: 'Filter by Schedule'),
                  ),
                ),
                // category filter removed per request
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final subject = (data['subjectName'] as String?) ?? '';
                  final desc = (data['description'] as String?) ?? '';
                  final scheduleTs = data['schedule'];
                  DateTime schedule = DateTime.now();
                  if (scheduleTs is Timestamp) schedule = scheduleTs.toDate();

                  final matchesQuery = _query.isEmpty || subject.toLowerCase().contains(_query.toLowerCase()) || desc.toLowerCase().contains(_query.toLowerCase());
                  final matchesSchedule = _matchesSchedule(schedule, _scheduleFilter);
                  return matchesQuery && matchesSchedule;
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('No study groups found'));

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data();
                    final subject = (data['subjectName'] as String?) ?? '';
                    final desc = (data['description'] as String?) ?? '';
                    final imageUrl = (data['imageUrl'] as String?) ?? '';
                    final scheduleTs = data['schedule'];
                    DateTime schedule = DateTime.now();
                    if (scheduleTs is Timestamp) schedule = scheduleTs.toDate();

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          // show details dialog
                          final dataMap = filtered[index].data();
                          final fs = FirestoreService();
                          final createdAtRaw = dataMap['createdAt'] ?? dataMap['created_at'];
                          final createdAtStr = _formatTimestamp(createdAtRaw) ?? 'Unknown';
                          final createdBy = dataMap['createdBy'] ?? dataMap['created_by'] ?? 'Unknown';
                          final room = dataMap['roomNumber'] ?? dataMap['room_number'] ?? '';
                          final totalSlots = dataMap['totalSlots'] ?? dataMap['total_slots'] ?? dataMap['slots'] ?? 0;
                          final occupiedSlots = dataMap['occupiedSlots'] ?? dataMap['occupied_slots'] ?? 0;
                          final remaining = ( (totalSlots is int ? totalSlots : int.tryParse(totalSlots.toString()) ?? 0) - (occupiedSlots is int ? occupiedSlots : int.tryParse(occupiedSlots.toString()) ?? 0)).clamp(0, 9999);
                          final scheduleRawLocal = dataMap['schedule'];
                          final scheduleStrLocal = (scheduleRawLocal is Timestamp) ? _formatTimestamp(scheduleRawLocal) ?? '' : (scheduleRawLocal?.toString() ?? '');

                          Future.microtask(() {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(subject),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (imageUrl.isNotEmpty) Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: SizedBox(width: double.infinity, height: 150, child: Image.network(imageUrl, fit: BoxFit.cover, loadingBuilder: (c, child, chunk) { if (chunk == null) return child; return const Center(child: CircularProgressIndicator()); }, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.broken_image)),)),
                                      ),
                                      Text('Created by: $createdBy', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Text('Created at: $createdAtStr'),
                                      const SizedBox(height: 12),
                                      if (desc.isNotEmpty) ...[
                                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Text(desc),
                                        const SizedBox(height: 8),
                                      ],
                                      if (room != null && room.toString().isNotEmpty) Text('Room: ${room.toString()}'),
                                      const SizedBox(height: 6),
                                      Text('Slots: $occupiedSlots / $totalSlots (remaining: $remaining)'),
                                      const SizedBox(height: 6),
                                      Text('Schedule: $scheduleStrLocal'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Back')),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final user = FirebaseAuth.instance.currentUser;
                                        final uid = user?.uid;
                                        if (uid == null) throw Exception('Sign in first');
                                        final userDoc = await fs.getUserDoc(uid);
                                        final profile = userDoc.exists ? (userDoc.data() as Map<String, dynamic>? ?? {}) : {};
                                        final member = {
                                          'uid': uid,
                                          'name': profile['name'] ?? user?.displayName ?? '',
                                          'email': profile['email'] ?? user?.email ?? '',
                                          'joinedAt': FieldValue.serverTimestamp(),
                                        };
                                        final groupId = filtered[index].id;
                                        await fs.joinStudyGroupWithMember(groupId, member);
                                        if (!context.mounted) return;
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group')));
                                      } catch (e) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join: ${e.toString()}'), backgroundColor: Colors.red));
                                      }
                                    },
                                    child: const Text('Join'),
                                  ),
                                ],
                              ),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 100, fit: BoxFit.cover)) : null,
                          title: Text(subject, style: GoogleFonts.cinzel(color: adduNavy)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(desc, style: GoogleFonts.lora(), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text('When: ${schedule.toLocal()}', style: GoogleFonts.roboto(fontSize: 12)),
                            ],
                          ),
                        ),
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

String? _formatTimestamp(dynamic t) {
  if (t == null) return null;
  if (t is Timestamp) {
    final dt = t.toDate().toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
  if (t is DateTime) {
    return t.toLocal().toIso8601String();
  }
  if (t is String) return t;
  return t.toString();
}

