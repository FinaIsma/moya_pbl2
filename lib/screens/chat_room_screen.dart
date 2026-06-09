import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String psikologUid;
  final String psikologName;
  final String psikologPhotoUrl;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.psikologUid,
    required this.psikologName,
    required this.psikologPhotoUrl,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}


class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textController  = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUid      = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _showAttachMenu   = false;
  bool _isSessionClosed = false;
  
  StreamSubscription? _roomSubscription;

  static const _primary   = Color(0xFF9ECAD6);
  static const _secondary = Color(0xFF748DAE);
  static const _accent    = Color(0xFFF5CBCB);
  static const _textMain  = Color(0xFF1A1A2E);
  static const _textSub   = Color(0xFF5A6A7E);

  // Bubble warna
  // User sendiri → teal (kanan)
  // Psikolog → pink (kiri)
  static const _bubbleSelf  = Color(0xFF9ECAD6);
  static const _bubbleOther = Color(0xFFF5CBCB);

  @override
  void initState() {
    super.initState();
    ChatService.markAsRead(widget.roomId);
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .set({'unread_user': 0}, SetOptions(merge: true));
        _roomSubscription = ChatService.streamRoom(widget.roomId)
        .listen((doc) {
          if (!mounted) return;

          final data = doc.data();

          setState(() {
            final status = data?['status'] ?? '';
            _isSessionClosed = status != 'Active';
          });
        });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mengunduh file...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 1. Encode URL untuk menghindari error karena spasi atau karakter aneh
      final safeUrl = Uri.encodeFull(url);
      final response = await http.get(Uri.parse(safeUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        
        // 2. Sanitasi nama file (ubah spasi dan karakter ilegal jadi underscore)
        // supaya sistem file Android/iOS tidak crash saat membuat file
        final safeFileName = fileName
            .replaceAll(RegExp(r'[^\w\s\.-]'), '_')
            .replaceAll(' ', '_');
            
        final file = File('${dir.path}/$safeFileName');

        await file.writeAsBytes(response.bodyBytes);

        // 3. Buka file
        final result = await OpenFilex.open(file.path);

        // Jika HP user tidak memiliki peninjau PDF/Word
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tidak bisa membuka file: ${result.message}')),
            );
          }
        }
      } else {
        // Jika server Cloudinary menolak (misal error 404 / 403)
        throw Exception('Gagal mengunduh (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 4), // Durasinya dipanjangin biar mudah dibaca
          ),
        );
      }
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String _formatDateDivider(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final target = DateTime(
    date.year,
    date.month,
    date.day,
  );

  final difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Hari Ini';
  }

  if (difference == 1) {
    return 'Kemarin';
  }

  return DateFormat('d MMMM yyyy', 'id_ID').format(date);
}

  Future<void> _sendText() async {
    if (_isSessionClosed) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await ChatService.sendText(roomId: widget.roomId, text: text);

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.roomId)
        .set({
      'last_message': text,
      'last_message_at': FieldValue.serverTimestamp(),
      'psikolog_uid': widget.psikologUid, 
      'user_uid': _currentUid,            
      // 'status': 'Active',
      'unread_psikolog': FieldValue.increment(1), 
    }, SetOptions(merge: true));
    
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
     if (_isSessionClosed) return;
    setState(() => _showAttachMenu = false);
    await ChatService.sendImage(roomId: widget.roomId);
    _scrollToBottom();
  }

  Future<void> _sendDocument() async {
 if (_isSessionClosed) return; 
    setState(() => _showAttachMenu = false);
    await ChatService.sendDocument(roomId: widget.roomId);
    _scrollToBottom();
  }

  // ─── Bubble widget ─────────────────────────────────────────
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
      content = GestureDetector(
        onTap: () {
          final url = data['file_url'] as String?;
          if (url != null && url.isNotEmpty) {
            final fileName =
                'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            _downloadAndOpenFile(url, fileName);
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 240
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: Image.network(
                data['file_url'] ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      content = GestureDetector(
        onTap: () {
          final url = data['file_url'] as String?;
          final fileName =
              data['file_name'] ?? 'document.file';

          if (url != null && url.isNotEmpty) {
            _downloadAndOpenFile(url, fileName);
          }
        },
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: _secondary,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['file_name'] ?? 'Document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Tap untuk membuka',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _textSub,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.download_rounded,
                color: _secondary,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isSelf
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isSelf ? 70 : 0,
          right: isSelf ? 0 : 70,
        ),

        // <-- INI paddingnya
        padding: type == 'text'
            ? const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              )
            : const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bubbleColor.withOpacity(0.85),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
          color: Colors.white.withOpacity(
            type == 'text' ? 0.35 : 0.7,
          ),
          width: 1,
        ),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isSelf ? 20 : 6),
            bottomRight: Radius.circular(isSelf ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            SizedBox(
              height: type == 'text' ? 4 : 8,
            ),
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

  Future<void> _showEndSessionDialog()
  async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'End Session?',
          ),
          content: const Text(
            'Consultation will be ended.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child: const Text(
                'End',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ChatService.endChatSession(
        widget.roomId,
      );

      _showRatingDialog();
    }
  }

  Future<void> _showRatingDialog()
async {
  double rating = 5;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          'Write your Rating',
        ),
        content: StatefulBuilder(
          builder: (
            context,
            setStateDialog,
          ) {
            return RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder:
                  (_, __) =>
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
              onRatingUpdate:
                  (value) {
                setStateDialog(() {
                  rating = value;
                });
              },
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await ChatService.submitRating(
                psikologId:
                    widget.psikologUid,
                userId:
                    _currentUid,
                rating: rating,
              );

              if (mounted) {
                Navigator.pop(
                  context,
                );
              }
            },
            child: const Text(
              'Submit',
            ),
          ),
        ],
      );
    },
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
                    backgroundImage: widget.psikologPhotoUrl.isNotEmpty
                        ? NetworkImage(widget.psikologPhotoUrl)
                        : null,
                    child: widget.psikologPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: _secondary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.psikologName,
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isSessionClosed)
                  TextButton.icon(
                    onPressed: _showEndSessionDialog,
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'End',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE4ECF0)),

            // ── Messages ─────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/bg_chat.png',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.09,
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: ChatService.streamMessages(widget.roomId),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                        ),
                      );
                    }

                    final docs = snap.data!.docs;
                    if (docs.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Start Conversation!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textSub,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        20,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data =
                            docs[i].data() as Map<String, dynamic>;

                        final currentTs =
                            data['created_at'] as Timestamp?;

                        bool showDateDivider = false;

                        if (currentTs != null) {
                          final currentDate = currentTs.toDate();

                          if (i == 0) {
                            showDateDivider = true;
                          } else {
                            final prevData =
                                docs[i - 1].data()
                                    as Map<String, dynamic>;

                            final prevTs =
                                prevData['created_at']
                                    as Timestamp?;

                            if (prevTs != null) {
                              final prevDate = prevTs.toDate();

                              showDateDivider =
                                  currentDate.day != prevDate.day ||
                                  currentDate.month != prevDate.month ||
                                  currentDate.year != prevDate.year;
                            }
                          }
                        }

                        return Column(
                          children: [
                            if (showDateDivider &&
                                currentTs != null)
                              _buildDateDivider(
                                currentTs.toDate(),
                              ),
                            _buildBubble(data),
                          ],
                        );
                      },
                    );
                  },
                ),
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

              if (_isSessionClosed)
               Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(
                  'This consultation session has ended',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),

            // ── Input bar ─────────────────────────────────────
 if (!_isSessionClosed)
                 Container(
                padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 10,
                  bottom: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4ECF0))),
                ),
                child: Row(
                  children: [
                    // + button
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

                  // Text field
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

                  // Send button
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

  Widget _buildDateDivider(DateTime date) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 16,
    ),
    child: Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFE4ECF0),
            thickness: 1,
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4F7),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.03,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],

            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color: const Color(0xFFD8E7ED),
            ),
          ),
          child: Text(
            _formatDateDivider(date),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSub,
            ),
          ),
        ),

        const Expanded(
          child: Divider(
            color: Color(0xFFE4ECF0),
            thickness: 1,
          ),
        ),
      ],
    ),
  );
}
}