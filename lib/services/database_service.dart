import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/deadline_model.dart';
import '../models/note_model.dart';
import '../models/chat_message_model.dart';
import '../models/private_message_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ROLE ENGINE ---
  // Determines access levels for CR/GR/Admin features
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] ?? 'student';
      }
      return 'student';
    } catch (e) {
      print("System Error (Role Engine): $e");
      return 'student';
    }
  }

  // --- CHAT HUB (SIDEBAR LOGIC) ---

  // REFINED: Fetches all active private frequencies for the Hub sidebar.
  // Includes automatic discovery for new inbound transmissions.
  Stream<List<Map<String, dynamic>>> getMyPrivateChats(String uid) {
    return _db.collection('private_chats')
        .where('participants', arrayContains: uid)
        .orderBy('last_active', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {

      try {
        final futures = snapshot.docs.map((doc) async {
          final data = doc.data();
          List participants = data['participants'] ?? [];

          // Isolate the ID of the other student in the frequency
          String otherUid = participants.firstWhere((id) => id != uid, orElse: () => "");

          if (otherUid.isNotEmpty) {
            var userDoc = await _db.collection('users').doc(otherUid).get();
            if (userDoc.exists) {
              var userData = userDoc.data() as Map<String, dynamic>;
              return {
                'chatId': doc.id,
                'otherUid': otherUid,
                'otherName': userData['name'] ?? "Unknown Student",
                'otherEnrollment': userData['enrollment'] ?? "N/A",
                'lastActive': data['last_active'],
              };
            }
          }
          return null;
        });

        final results = await Future.wait(futures);
        return results.whereType<Map<String, dynamic>>().toList();
      } catch (e) {
        print("Grid Error (Sidebar Sync): $e");
        return [];
      }
    });
  }

  // --- PRIVATE P2P SYSTEM ---

  // 1. Locate a student's profile via Enrollment ID
  Future<Map<String, dynamic>?> getUserByEnrollment(String enrollment) async {
    try {
      var snapshot = await _db.collection('users')
          .where('enrollment', isEqualTo: enrollment)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {
          'uid': snapshot.docs.first.id,
          'name': snapshot.docs.first['name'],
        };
      }
    } catch (e) {
      print("System Error (User Search): $e");
    }
    return null;
  }

  // 2. Generate a unique ID for a private channel
  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Sorting ensures both users target the same frequency doc
    return ids.join('_');
  }

  // 3. Streams private messages for a specific point-to-point link
  Stream<List<PrivateMessage>> getPrivateMessages(String currentUid, String otherUid) {
    String chatId = _getChatId(currentUid, otherUid);
    return _db.collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PrivateMessage.fromFirestore(d)).toList());
  }

  // 4. Send a private transmission (Supports Resource Links)
  Future<void> sendPrivateMessage(String text, String senderId, String receiverId, {String? linkUrl, String? linkTitle}) async {
    String chatId = _getChatId(senderId, receiverId);

    // Add message to subcollection
    await _db.collection('private_chats').doc(chatId).collection('messages').add({
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'linkUrl': linkUrl,
      'linkTitle': linkTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update parent doc last_active (Triggers sidebar re-sort)
    await _db.collection('private_chats').doc(chatId).set({
      'last_active': FieldValue.serverTimestamp(),
      'participants': [senderId, receiverId]
    }, SetOptions(merge: true));
  }

  // --- EVENTS ---
  Stream<List<CampusEvent>> getEvents() {
    return _db.collection('events').orderBy('date').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CampusEvent.fromFirestore(doc)).toList());
  }

  Future<void> addEvent(String title, String desc, DateTime date, String loc, double lat, double lng) async {
    await _db.collection('events').add({
      'title': title,
      'description': desc,
      'date': Timestamp.fromDate(date),
      'location': loc,
      'position': GeoPoint(lat, lng),
    });
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  // --- DEADLINES ---
  Stream<List<Deadline>> getDeadlines() {
    return _db.collection('deadlines').orderBy('dueDate').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Deadline.fromFirestore(doc)).toList());
  }

  Future<void> addDeadline(String title, String subject, DateTime date,
      {required String department, required String semester}) async {
    final existing = await _db.collection('deadlines')
        .where('title', isEqualTo: title)
        .where('subject', isEqualTo: subject)
        .get();

    if (existing.docs.isEmpty) {
      await _db.collection('deadlines').add({
        'title': title,
        'subject': subject,
        'dueDate': Timestamp.fromDate(date),
        'department': department,
        'semester': semester,
        'isCompleted': false,
      });
    }
  }

  Future<void> toggleDeadline(String id, bool currentStatus) async {
    await _db.collection('deadlines').doc(id).update({
      'isCompleted': !currentStatus,
    });
  }

  Future<void> deleteDeadline(String id) async {
    await _db.collection('deadlines').doc(id).delete();
  }

  // --- NOTES ---
  Stream<List<Note>> getNotes() {
    return _db.collection('notes').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Future<void> addNote(String title, String dept, String link, String uploader,
      {required String semester, required String course}) async {
    await _db.collection('notes').add({
      'title': title,
      'department': dept,
      'semester': semester,
      'course': course,
      'fileUrl': link,
      'uploaderName': uploader,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }

  // --- GLOBAL CHAT SYSTEM ---
  Stream<List<ChatMessage>> getMessages() {
    return _db
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  // Global Transmission (Supports Resource Links)
  Future<void> sendMessage(String text, String senderId, String senderName, {String? linkUrl, String? linkTitle}) async {
    await _db.collection('messages').add({
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'linkUrl': linkUrl,
      'linkTitle': linkTitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}