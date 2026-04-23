import 'package:cloud_firestore/cloud_firestore.dart';

/// FirestoreService
///
/// Centralized helper functions for reading and writing to Firestore.
/// Use Stream methods for real-time UI and Future methods for one-off actions.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------- Subjects --------------------
  Stream<QuerySnapshot> subjectsStream({String orderBy = 'name'}) {
    return _db.collection('subjects').orderBy(orderBy).snapshots();
  }

  Future<DocumentReference> addSubject(String name) async {
    return await _db.collection('subjects').add({'name': name});
  }

  Future<void> updateSubject(String id, String name) async {
    await _db.collection('subjects').doc(id).update({'name': name});
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  // -------------------- Tutors --------------------
  Stream<QuerySnapshot> tutorsStream() => _db.collection('tutors').snapshots();

  Future<DocumentReference> addTutor(Map<String, dynamic> data) async {
    return await _db.collection('tutors').add(data);
  }

  Future<void> updateTutor(String id, Map<String, dynamic> data) async {
    await _db.collection('tutors').doc(id).update(data);
  }

  Future<void> deleteTutor(String id) async {
    await _db.collection('tutors').doc(id).delete();
  }

  Future<void> setTutorVerified(String id, bool verified) async {
    await _db.collection('tutors').doc(id).update({'verified': verified});
  }

  // -------------------- Study Groups --------------------
  Stream<QuerySnapshot> studyGroupsStream() => _db.collection('study_groups').snapshots();

  Future<DocumentReference> addStudyGroup(Map<String, dynamic> data) async {
    return await _db.collection('study_groups').add(data);
  }

  Future<void> updateStudyGroup(String id, Map<String, dynamic> data) async {
    await _db.collection('study_groups').doc(id).update(data);
  }

  Future<void> deleteStudyGroup(String id) async {
    await _db.collection('study_groups').doc(id).delete();
  }

  /// Join a study group: decrement slots and optionally add member to members array.
  Future<void> joinStudyGroup(String groupId, String userId) async {
    final docRef = _db.collection('study_groups').doc(groupId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Group not found');
      final data = snap.data() as Map<String, dynamic>;
      final int slots = (data['slots'] ?? 0) as int;
      if (slots <= 0) throw Exception('No slots available');
      tx.update(docRef, {'slots': slots - 1});
      // optional: add member to members array
      tx.update(docRef, {
        'members': FieldValue.arrayUnion([userId])
      });
    });
  }

  /// Join a study group and add a structured member object to the members array.
  /// `member` is a Map containing at least `uid` and optionally `name`, `email`, etc.
  Future<void> joinStudyGroupWithMember(String groupId, Map<String, dynamic> member) async {
    final docRef = _db.collection('study_groups').doc(groupId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Group not found');
      final data = snap.data() as Map<String, dynamic>;

      // Determine total and occupied slots using possible field names
      dynamic totalRaw = data['totalSlots'] ?? data['total_slots'] ?? data['slots'];
      dynamic occupiedRaw = data['occupiedSlots'] ?? data['occupied_slots'] ?? data['occupied'] ?? 0;

      int total = 0;
      int occupied = 0;
      if (totalRaw is int) total = totalRaw;
      else if (totalRaw is double) total = totalRaw.toInt();
      else if (totalRaw is String) total = int.tryParse(totalRaw) ?? 0;

      if (occupiedRaw is int) occupied = occupiedRaw;
      else if (occupiedRaw is double) occupied = occupiedRaw.toInt();
      else if (occupiedRaw is String) occupied = int.tryParse(occupiedRaw) ?? 0;

      if (total - occupied <= 0) throw Exception('No slots available');

      // Use members subcollection with doc ID = uid to prevent duplicates
      final membersColl = docRef.collection('members');
      final uid = member['uid']?.toString();
      if (uid == null || uid.isEmpty) throw Exception('member.uid required');
      final memberRef = membersColl.doc(uid);

      final existing = await tx.get(memberRef);
      if (existing.exists) {
        throw Exception('Already joined');
      }

      final memberToWrite = Map<String, dynamic>.from(member);
      // ensure joinedAt is server timestamp if not provided
      if (!memberToWrite.containsKey('joinedAt') && !memberToWrite.containsKey('joined_at')) {
        memberToWrite['joinedAt'] = FieldValue.serverTimestamp();
      }

      tx.set(memberRef, memberToWrite);

      // increment occupiedSlots field atomically
      tx.update(docRef, {'occupiedSlots': FieldValue.increment(1)});

      // Also create a session record so the student's My Sessions list reflects this join.
      final sessionRef = _db.collection('sessions').doc();
      final sessionData = {
        'student_id': memberToWrite['uid'],
        'group_id': groupId,
        'subject': data['subjectName'] ?? data['subject_name'] ?? data['name'] ?? '',
        'schedule': data['schedule'],
        'roomNumber': data['roomNumber'] ?? data['room_number'] ?? '',
        'type': 'study_group',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      };
      tx.set(sessionRef, sessionData);
    });
  }

  /// Returns true if the given uid is a member of the study group.
  /// Checks members subcollection (doc id == uid) and falls back to older
  /// members array or members map field for compatibility.
  Future<bool> isMember(String groupId, String uid) async {
    final docRef = _db.collection('study_groups').doc(groupId);
    final snap = await docRef.get();
    if (!snap.exists) return false;
  final data = snap.data() ?? {};

    // Fast path: members map on document
    final membersMap = data['members'];
    if (membersMap is Map && membersMap.containsKey(uid)) return true;

    // Legacy: members array on document
    final membersArray = data['members'] as List<dynamic>?;
    if (membersArray != null) {
      for (final m in membersArray) {
        try {
          if (m is String && m == uid) return true;
          if (m is Map && m['uid'] == uid) return true;
        } catch (_) {}
      }
    }

    // Check members subcollection with doc id = uid
    final memberDoc = await docRef.collection('members').doc(uid).get();
    if (memberDoc.exists) return true;

    return false;
  }

  /// Add `roomNumber` field to all study_groups documents that are missing it.
  /// Uses batched writes in groups of 400 for efficiency. Default value will be
  /// written when the field is missing or null.
  Future<void> migrateAddRoomNumber({String defaultValue = 'TBD'}) async {
    final coll = _db.collection('study_groups');
    final snapshot = await coll.get();
    final docs = snapshot.docs;
    const batchSize = 400; // keep well below 500
    for (var i = 0; i < docs.length; i += batchSize) {
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      final batch = _db.batch();
      for (var j = i; j < end; j++) {
        final d = docs[j];
        final data = d.data();
        if (data.containsKey('roomNumber') && data['roomNumber'] != null && data['roomNumber'].toString().trim().isNotEmpty) continue;
        final ref = coll.doc(d.id);
        batch.update(ref, {'roomNumber': defaultValue});
      }
      await batch.commit();
    }
  }

  // -------------------- Sessions --------------------
  Stream<QuerySnapshot> sessionsStream() => _db.collection('sessions').snapshots();

  Stream<QuerySnapshot> sessionsForUserStream(String userId) => _db.collection('sessions').where('student_id', isEqualTo: userId).snapshots();

  Future<DocumentReference> bookSession({required String tutorId, required String studentId, required String subject, required Map<String, dynamic> schedule}) async {
    final data = {
      'tutor_id': tutorId,
      'student_id': studentId,
      'subject': subject,
      'schedule': schedule,
      'status': 'booked',
      'createdAt': FieldValue.serverTimestamp(),
    };
    return await _db.collection('sessions').add(data);
  }

  Future<void> updateSessionStatus(String id, String status) async {
    await _db.collection('sessions').doc(id).update({'status': status});
  }

  /// Remove a student's membership from a study group and delete the associated session.
  /// This will try to find the member document under `study_groups/{groupId}/members`
  /// where `uid == studentId`, delete it, decrement occupiedSlots (if > 0), and
  /// delete the session document `sessions/{sessionId}`. It performs a transaction
  /// for the writes and a small query beforehand to locate the member doc if present.
  Future<void> removeStudyGroupMembershipAndSession({required String groupId, required String studentId, required String sessionId}) async {
    final membersColl = _db.collection('study_groups').doc(groupId).collection('members');
    // Try to locate the member doc first (queries cannot run inside a transaction on some platforms)
    final q = await membersColl.where('uid', isEqualTo: studentId).limit(1).get();
    final memberDocId = q.docs.isNotEmpty ? q.docs.first.id : null;

    final groupRef = _db.collection('study_groups').doc(groupId);
    final sessionRef = _db.collection('sessions').doc(sessionId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(groupRef);
      if (!snap.exists) {
        // still delete session if group missing
        tx.delete(sessionRef);
        return;
      }

      // delete member document if found
      if (memberDocId != null) {
        final memberRef = membersColl.doc(memberDocId);
        tx.delete(memberRef);
      }

      // decrement occupiedSlots safely
      final data = snap.data() as Map<String, dynamic>;
      dynamic occupiedRaw = data['occupiedSlots'] ?? data['occupied_slots'] ?? data['occupied'] ?? 0;
      int occupied = 0;
      if (occupiedRaw is int) occupied = occupiedRaw;
      else if (occupiedRaw is double) occupied = occupiedRaw.toInt();
      else if (occupiedRaw is String) occupied = int.tryParse(occupiedRaw) ?? 0;
      if (occupied > 0) {
        tx.update(groupRef, {'occupiedSlots': FieldValue.increment(-1)});
      }

      // delete session doc
      tx.delete(sessionRef);
    });
  }

  // -------------------- Ratings --------------------
  Stream<QuerySnapshot> ratingsStream() => _db.collection('ratings').snapshots();

  Future<DocumentReference> addRating(Map<String, dynamic> data) async {
    return await _db.collection('ratings').add(data);
  }

  // -------------------- Users --------------------
  Stream<QuerySnapshot> usersStream() => _db.collection('users').snapshots();

  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
  }

  // -------------------- Search helpers --------------------
  /// Search subjects by keyword (simple case-insensitive contains match).
  Future<List<QueryDocumentSnapshot>> searchSubjects(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    final q = await _db.collection('subjects').where('name', isGreaterThanOrEqualTo: keyword).where('name', isLessThanOrEqualTo: '$keyword\uf8ff').get();
    return q.docs;
  }

  /// Find tutors for a subject, optionally only verified tutors.
  Stream<QuerySnapshot> tutorsForSubjectStream(String subject, {bool onlyVerified = true}) {
    final query = _db.collection('tutors').where('subjects', arrayContains: subject);
    if (onlyVerified) return query.where('verified', isEqualTo: true).snapshots();
    return query.snapshots();
  }
}
