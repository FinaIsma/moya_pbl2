import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatRoomPsikologScreen extends StatefulWidget {
  final String roomId;
  final String userUid;
  final String userName;
  final String userPhotoUrl;

  const ChatRoomPsikologScreen({
    super.key,
    required this.roomId,
    required this.userUid,
    required this.userName,
    required this.userPhotoUrl,
  });

  @override
  State<ChatRoomPsikologScreen> createState() => _ChatRoomPsikologScreenState();
}

class _ChatRoomPsikologScreenState extends State<ChatRoomPsikologScreen> {
  final _textController   = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUid       = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _showAttachMenu    = false;

  static const _primary   = Color(0xFF9ECAD6);
  static const _secondary = Color(0xFF748DAE);
  static const _accent    = Color(0xFFF5CBCB);
  static const _textMain  = Color(0xFF1A1A2E);
  static const _textSub   = Color(0xFF5A6A7E);

  // Psikolog POV — kebalik dari user POV
  // Psikolog sendiri → pink (kanan)
  // User → teal (kiri)
  static const _bubbleSelf  = Color(0xFFF5CBCB);
  static const _bubbleOther = Color(0xFF9ECAD6);

  @override
  void initState() {
    super.initState();
    ChatService.markAsRead(widget.roomId);

    FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(widget.roomId)
      .update({'unread_count': 0});
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await ChatService.sendText(roomId: widget.roomId, text: text);
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    setState(() => _showAttachMenu = false);
    await ChatService.sendImage(roomId: widget.roomId);
    _scrollToBottom();
  }

  Future<void> _sendDocument() async {
    setState(() => _showAttachMenu = false);
    await ChatService.sendDocument(roomId: widget.roomId);
    _scrollToBottom();
  }

  Widget _buildBubble(Map<String, dynamic> data) {
    final isSelf   = data['sender_uid'] == _currentUid;
    final type     = data['type'] as String? ?? 'text';
    final ts       = data['created_at'] as Timestamp?;
    final isRead   = data['is_read'] as bool? ?? false;

    // Psikolog POV: diri sendiri = pink (kanan), user = teal (kiri)
    final bubbleColor = isSelf ? _bubbleSelf : _bubbleOther;

    Widget content;

    if (type == 'text') {
      content = Text(
        data['content'] ?? '',
        style: GoogleFonts.poppins(
          fontSize: 13, color: _textMain, height: 1.5,
        ),
      );
    } else if (type == 'image') {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          data['file_url'] ?? '',
          width: 200,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 200, height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
            color: _secondary, size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              data['file_name'] ?? 'Document',
              style: GoogleFonts.poppins(
                fontSize: 13, color: _textMain,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6, bottom: 6,
          left:  isSelf ? 60 : 0,
          right: isSelf ? 0  : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isSelf ? 18 : 4),
            bottomRight: Radius.circular(isSelf ? 4  : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(ts),
                  style: GoogleFonts.poppins(
                    fontSize: 10, color: _textSub,
                  ),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? _secondary : _textSub,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: _textMain, size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _accent,
                    backgroundImage: widget.userPhotoUrl.isNotEmpty
                        ? NetworkImage(widget.userPhotoUrl)
                        : null,
                    child: widget.userPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: _secondary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.userName,
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE4ECF0)),

            // ── Messages ─────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ChatService.streamMessages(widget.roomId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primary),
                    );
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('Belum ada pesan.',
                        style: GoogleFonts.poppins(
                          fontSize: 14, color: _textSub,
                        ),
                      ),
                    );
                  }

                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _buildBubble(data);
                    },
                  );
                },
              ),
            ),

            // ── Attach menu popup ─────────────────────────────
            if (_showAttachMenu)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4ECF0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8, offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined,
                        color: _secondary,
                      ),
                      title: Text('Document',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: _textMain,
                        ),
                      ),
                      onTap: _sendDocument,
                    ),
                    const Divider(height: 1, color: Color(0xFFE4ECF0)),
                    ListTile(
                      leading: const Icon(Icons.image_outlined,
                        color: _secondary,
                      ),
                      title: Text('Photos',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: _textMain,
                        ),
                      ),
                      onTap: _sendImage,
                    ),
                  ],
                ),
              ),

            // ── Input bar ─────────────────────────────────────
            Container(
              padding: EdgeInsets.only(
                left: 12, right: 12, top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE4ECF0))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => _showAttachMenu = !_showAttachMenu,
                    ),
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(
                        color: _secondary, shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showAttachMenu ? Icons.close : Icons.add,
                        color: Colors.white, size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.poppins(
                        fontSize: 14, color: _textMain,
                      ),
                      decoration: InputDecoration(
                        hintText: '',
                        filled: true,
                        fillColor: const Color(0xFFE8E8E8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10,
                        ),
                      ),
                      onTap: () {
                        if (_showAttachMenu) {
                          setState(() => _showAttachMenu = false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(
                        color: _secondary, shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
