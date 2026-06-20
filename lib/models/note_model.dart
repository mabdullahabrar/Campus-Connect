import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String department;
  final String semester;
  final String course;
  final String fileUrl;
  final String uploaderName;

  Note({
    required this.id,
    required this.title,
    required this.department,
    required this.semester,
    required this.course,
    required this.fileUrl,
    required this.uploaderName
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      department: data['department'] ?? '',
      semester: data['semester'] ?? '',
      course: data['course'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      uploaderName: data['uploaderName'] ?? '',
    );
  }
}