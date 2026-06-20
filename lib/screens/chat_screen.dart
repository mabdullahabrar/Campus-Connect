import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../models/chat_message_model.dart';
import '../models/private_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _db = DatabaseService();
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Stream Caching for Stability on Chrome
  Stream<List<Map<String, dynamic>>>? _sidebarStream;
  Stream<List<ChatMessage>>? _globalMsgStream;

  Map<String, dynamic>? _activeChat; // Null = Global Grid
  String _searchFilter = "";

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _sidebarStream = _db.getMyPrivateChats(_user!.uid);
      _globalMsgStream = _db.getMessages();
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- TRANSMISSION LOGIC ---

  void _handleSend() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _user == null) return;
    _msgController.clear();

    if (_activeChat == null) {
      await _db.sendMessage(text, _user!.uid, _user!.displayName ?? "Student");
    } else {
      await _db.sendPrivateMessage(text, _user!.uid, _activeChat!['otherUid']);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  // --- RESOURCE LINK UPLINK ---

  void _showLinkDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
        title: Text("ATTACH RESOURCE", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Description (e.g. AI Notes)", labelStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "URL (Drive/Web Link)", labelStyle: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                String title = titleController.text.isEmpty ? "View Resource" : titleController.text;
                if (_activeChat == null) {
                  await _db.sendMessage("", _user!.uid, _user!.displayName ?? "Student", linkUrl: url, linkTitle: title);
                } else {
                  await _db.sendPrivateMessage("", _user!.uid, _activeChat!['otherUid'], linkUrl: url, linkTitle: title);
                }
                if (mounted) Navigator.pop(context);
                _scrollToBottom();
              }
            },
            child: const Text("TRANSMIT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: Text("OFFLINE")));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 320,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
            child: Column(
              children: [
                _buildSidebarHeader(),
                _buildSidebarSearch(),
                Expanded(
                  child: ListView(
                    children: [
                      _buildChatTile(
                        title: "COMMUNITY GRID",
                        subtitle: "Global Campus Feed",
                        icon: Icons.public_rounded,
                        isActive: _activeChat == null,
                        onTap: () => setState(() => _activeChat = null),
                      ),
                      const Padding(padding: EdgeInsets.fromLTRB(25, 30, 0, 10), child: Text("PRIVATE SECURE LINES", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))),
                      _buildPrivateChatList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // --- TERMINAL ---
          Expanded(
            child: Column(
              children: [
                _buildTerminalHeader(),
                Expanded(
                  key: ValueKey(_activeChat?['otherUid'] ?? "global"),
                  child: _buildMessageFeed(),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 40, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("HUB", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.cyanAccent, size: 20), onPressed: _startNewChatDialog),
        ],
      ),
    );
  }

  Widget _buildSidebarSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() => _searchFilter = v.toLowerCase()),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: "Filter...", hintStyle: const TextStyle(color: Colors.white10),
          prefixIcon: const Icon(Icons.search, color: Colors.white10, size: 16),
          filled: true, fillColor: Colors.white.withOpacity(0.02),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPrivateChatList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _sidebarStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final chats = snapshot.data!.where((c) => c['otherName'].toLowerCase().contains(_searchFilter)).toList();
        return Column(
          children: chats.map((chat) => _buildChatTile(
            title: chat['otherName'],
            subtitle: chat['otherEnrollment'],
            icon: Icons.person_rounded,
            isActive: _activeChat?['otherUid'] == chat['otherUid'],
            onTap: () => setState(() => _activeChat = chat),
          )).toList(),
        );
      },
    );
  }

  Widget _buildChatTile({required String title, required String subtitle, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isActive ? Colors.cyanAccent : Colors.white.withOpacity(0.03),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white30, size: 14),
      ),
      title: Text(title, style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10)),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_activeChat == null ? "COMMUNITY GRID" : _activeChat!['otherName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_activeChat == null ? "Live Broadcast" : "SECURE P2P LINK", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 8)),
          ]),
          const Spacer(),
          const Icon(Icons.shield_outlined, color: Colors.white10, size: 18),
        ],
      ),
    );
  }

  Widget _buildMessageFeed() {
    final stream = _activeChat == null ? _globalMsgStream : _db.getPrivateMessages(_user!.uid, _activeChat!['otherUid']);
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        final List msgs = snapshot.data as List;
        return ListView.builder(
          controller: _scrollController, reverse: true, padding: const EdgeInsets.all(25),
          itemCount: msgs.length,
          itemBuilder: (c, i) {
            final m = msgs[i];
            return _buildBubble(m, m.senderId == _user!.uid);
          },
        );
      },
    );
  }

  Widget _buildBubble(dynamic msg, bool isMe) {
    String text = "";
    String? linkUrl;
    String? linkTitle;
    String? senderName;

    if (msg is ChatMessage) {
      text = msg.text;
      senderName = msg.senderName;
      linkUrl = msg.linkUrl;
      linkTitle = msg.linkTitle;
    } else if (msg is PrivateMessage) {
      text = msg.text;
      linkUrl = msg.linkUrl;
      linkTitle = msg.linkTitle;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text(senderName.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 8))),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
            decoration: BoxDecoration(
              color: isMe ? Colors.cyanAccent.withOpacity(0.05) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(15).copyWith(
                bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
              ),
              border: Border.all(color: isMe ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CORRECTED LINK CARD ---
                if (linkUrl != null && linkUrl.isNotEmpty)
                  Builder(
                      builder: (context) {
                        // Promotions to non-nullable strings for the async block
                        final String urlToLaunch = linkUrl!;
                        return InkWell(
                          onTap: () async {
                            final Uri uri = Uri.parse(urlToLaunch);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1))
                            ),
                            child: Row(children: [
                              const Icon(Icons.insert_link_rounded, color: Colors.cyanAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(linkTitle ?? "View Resource", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.open_in_new, color: Colors.white24, size: 12),
                            ]),
                          ),
                        );
                      }
                  ),
                if (text.isNotEmpty)
                  Padding(padding: const EdgeInsets.all(12), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1E293B), border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_link_rounded, color: Colors.white38), onPressed: _showLinkDialog),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(hintText: "Initialize transmission...", hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(icon: const Icon(Icons.send_rounded, color: Colors.cyanAccent), onPressed: _handleSend),
        ],
      ),
    );
  }

  void _startNewChatDialog() {
    final TextEditingController enrollController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),
        title: Text("NEW LINK", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14)),
        content: TextField(
          controller: enrollController, autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Target Enrollment ID", labelStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABORT", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              var target = await _db.getUserByEnrollment(enrollController.text.trim());
              if (target != null) {
                if (mounted) Navigator.pop(context);
                setState(() => _activeChat = {'otherUid': target['uid'], 'otherName': target['name'], 'otherEnrollment': enrollController.text.trim()});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ID not found in the grid.")));
              }
            },
            child: const Text("CONNECT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}