import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String? linkUrl;   // NEW field
  final String? linkTitle; // NEW field

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.linkUrl,
    this.linkTitle,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Student',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      linkUrl: data['linkUrl'],
      linkTitle: data['linkTitle'],
    );
  }
}