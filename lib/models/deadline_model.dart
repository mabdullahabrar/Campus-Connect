import 'package:cloud_firestore/cloud_firestore.dart';

class Deadline {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final bool isCompleted;
  final String department;
  final String semester;

  Deadline({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    required this.department,
    required this.semester,
  });

  factory Deadline.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Deadline(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      department: data['department'] ?? 'CS',
      semester: data['semester'] ?? 'N/A',
    );
  }
}