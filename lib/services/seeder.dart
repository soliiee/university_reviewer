import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

final List<String> _subjects = [
  'IT 321 - Software Engineering',
  'Theo 141 - Theology',
  'Math 101 - Calculus I',
  'CS 201 - Data Structures',
  'Eng 110 - Academic Writing',
  'Phys 120 - Physics',
  'Chem 101 - General Chemistry',
  'Hist 100 - Philippine History',
  'Bio 130 - General Biology',
  'Econ 101 - Principles of Economics',
  'PSY 101 - Introduction to Psychology',
  'BUS 210 - Principles of Management',
  'Soc 101 - Sociology',
  'Phil 101 - Philosophy',
  'Acct 101 - Financial Accounting'
];

final List<String> _studentNames = [
  'Juan Dela Cruz',
  'Maria Santos',
  'Pedro Reyes',
  'Ana Lopez',
  'Mark dela Rosa',
  'Rosa Lim',
  'Carlos Tan',
  'Liza Bautista',
  'Miguel Navarro',
  'Isabel Cruz',
  'Andres Villanueva',
  'Bea Gonzales',
  'Diego Ramos',
  'Ella Mendoza',
  'Freddie Aguilar',
  'Gina Velasco',
  'Hector Dizon',
  'Ivy Santos',
  'Jomar Perez',
  'Karla Lim'
];

Future<void> seedInitialData() async {
  final db = FirebaseFirestore.instance;
  final rand = Random();

  // collect tutor ids to assign randomly
  final tutorSnapshot = await db.collection('tutors').get();
  final tutorIds = tutorSnapshot.docs.map((d) => d.id).toList();

  for (var i = 1; i <= 20; i++) {
    final subject = _subjects[rand.nextInt(_subjects.length)];
    final creator = _studentNames[rand.nextInt(_studentNames.length)];
    final daysAhead = rand.nextInt(60) + 1; // schedule within next 60 days
    final schedule = DateTime.now().add(Duration(days: daysAhead, hours: rand.nextInt(6) + 12));
    final slots = rand.nextInt(8) + 2;
  final imageUrl = 'https://picsum.photos/seed/study_hall_$i/400/300';
  final assignedTutor = tutorIds.isNotEmpty ? tutorIds[rand.nextInt(tutorIds.length)] : null;

    final doc = {
      'subjectName': subject,
      'description': 'Study group for $subject created by $creator. Join us to review core topics and practice problems.',
      'schedule': Timestamp.fromDate(schedule),
      'totalSlots': slots,
      'occupiedSlots': rand.nextInt(slots),
      'imageUrl': imageUrl,
      'assigned_tutor_id': assignedTutor,
      'createdBy': creator,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await db.collection('study_groups').add(doc);
  }
}
