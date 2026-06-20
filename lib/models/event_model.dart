import 'package:cloud_firestore/cloud_firestore.dart';

class CampusEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final double latitude;
  final double longitude;

  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory CampusEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint pos = data['position'] ?? const GeoPoint(33.6493, 73.0244);
    return CampusEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? 'Bahria University',
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }
}