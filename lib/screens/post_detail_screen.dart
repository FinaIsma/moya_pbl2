import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/display_name_helper.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _replyController = TextEditingController();
  final _currentUser     = FirebaseAuth.instance.currentUser;
  bool _isSending        = false;

  static const _primary   = Color(0xFF9ECAD6);
  static const _secondary = Color(0xFF748DAE);
  static const _accent    = Color(0xFFF5CBCB);
  static const _textMain  = Color(0xFF1A1A2E);
  static const _textSub   = Color(0xFF5A6A7E);

  static const List<Color> _avatarColors = [
    Color(0xFFD4A574), Color(0xFF9B8DB4), Color(0xFF7BAE8F),
    Color(0xFF748DAE), Color(0xFFE07B8A), Color(0xFF9ECAD6),
  ];

  Color _getAvatarColor(String uid) =>
      _avatarColors[uid.hashCode.abs() % _avatarColors.length];

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return '${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24)   return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  String _formatLikes(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }

  Future<void> _togglePostLike(List likes) async {
    final uid = _currentUser?.uid ?? '';
    final ref = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);
    if (likes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> _toggleReplyLike(String replyId, List likes) async {
    final uid = _currentUser?.uid ?? '';
    final ref = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .collection('replies')
        .doc(replyId);
    if (likes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> _sendReply(String postAuthorDisplayName) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .collection('replies')
          .add({
        'uid':         _currentUser?.uid ?? '',
        'content':     text,
        'likes':       [],
        'replyToName': postAuthorDisplayName, // nama yang ditampilkan post author
        'createdAt':   FieldValue.serverTimestamp(),
      });

      _replyController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim reply.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFE07B7B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .doc(widget.postId)
              .snapshots(),
          builder: (context, postSnap) {
            if (!postSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            final postData  = postSnap.data!.data() as Map<String, dynamic>;
            final postUid   = postData['uid'] as String? ?? '';
            final postLikes = List.from(postData['likes'] ?? []);
            final postLiked = postLikes.contains(_currentUser?.uid ?? '');
            final postTs    = postData['createdAt'] as Timestamp?;
            final isOwnPost = DisplayNameHelper.isCurrentUser(postUid);

            return FutureBuilder<String>(
              future: DisplayNameHelper.getDisplayName(postUid),
              builder: (context, postNameSnap) {
                final postAuthorName = postNameSnap.data ??
                    (isOwnPost ? 'You' : 'Anonymous...');

                return Column(
                  children: [
                    // ── AppBar ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _textMain, size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Post',
                            style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: _textMain,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE4ECF0)),

                    // ── Scrollable body ───────────────────
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community_posts')
                            .doc(widget.postId)
                            .collection('replies')
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, replySnap) {
                          final replies = replySnap.data?.docs ?? [];

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16,
                            ),
                            children: [
                              // ── Original Post ──────────
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE4ECF0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isOwnPost
                                              ? _secondary
                                              : _getAvatarColor(postUid),
                                          child: const Icon(Icons.person,
                                            color: Colors.white, size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(postAuthorName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _textMain,
                                                  ),
                                                ),
                                                if (isOwnPost) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 7, vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _primary.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text('You',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: _secondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(_formatTime(postTs),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12, color: _textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(postData['content'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13, color: _textMain, height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ── Like + Reply ───────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () => _togglePostLike(postLikes),
                                    child: Row(
                                      children: [
                                        Icon(
                                          postLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: postLiked
                                              ? Colors.red
                                              : const Color(0xFFABB8C3),
                                          size: 22,
                                        ),
                                        if (postLikes.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          Text(_formatLikes(postLikes.length),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13, color: _textSub,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                    width: 36, height: 36,
                                    decoration: const BoxDecoration(
                                      color: _secondary, shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.reply_rounded,
                                      color: Colors.white, size: 18,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ── Replies Header ─────────
                              Text('Replies',
                                style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: _textMain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Divider(color: Color(0xFFE4ECF0)),
                              const SizedBox(height: 8),

                              // ── Reply List ─────────────
                              if (replies.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Belum ada balasan. Jadilah yang pertama!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13, color: _textSub,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...replies.map((replyDoc) {
                                  final rd      = replyDoc.data() as Map<String, dynamic>;
                                  final rUid    = rd['uid'] as String? ?? '';
                                  final rLikes  = List.from(rd['likes'] ?? []);
                                  final rLiked  = rLikes.contains(_currentUser?.uid ?? '');
                                  final rTs     = rd['createdAt'] as Timestamp?;
                                  final replyTo = rd['replyToName'] as String? ?? 'Anonymous';
                                  final isOwnReply = DisplayNameHelper.isCurrentUser(rUid);

                                  return FutureBuilder<String>(
                                    future: DisplayNameHelper.getDisplayName(rUid),
                                    builder: (_, rNameSnap) {
                                      final rName = rNameSnap.data ??
                                          (isOwnReply ? 'You' : 'Anonymous...');

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: isOwnReply
                                                      ? _secondary
                                                      : _getAvatarColor(rUid),
                                                  child: const Icon(Icons.person,
                                                    color: Colors.white, size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13, color: _textMain,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: rName,
                                                          style: const TextStyle(
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                        const TextSpan(text: ' replies to '),
                                                        TextSpan(
                                                          text: replyTo,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(_formatTime(rTs),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11, color: _textSub,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFFE4ECF0),
                                                ),
                                              ),
                                              child: Text(rd['content'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13, color: _textMain,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _toggleReplyLike(
                                                    replyDoc.id, rLikes,
                                                  ),
                                                  child: Icon(
                                                    rLiked
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: rLiked
                                                        ? Colors.red
                                                        : const Color(0xFFABB8C3),
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Container(
                                                  width: 36, height: 36,
                                                  decoration: const BoxDecoration(
                                                    color: _secondary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.reply_rounded,
                                                    color: Colors.white, size: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }),
                            ],
                          );
                        },
                      ),
                    ),

                    // ── Reply Input ───────────────────────
                    const Divider(height: 1, color: Color(0xFFE4ECF0)),
                    FutureBuilder<String>(
                      // Nama saya sendiri untuk input bar
                      future: DisplayNameHelper.getDisplayName(
                        _currentUser?.uid ?? '',
                      ),
                      builder: (_, myNameSnap) {
                        final myName = myNameSnap.data ?? 'You';

                        return Container(
                          color: const Color(0xFFF8FAFB),
                          padding: EdgeInsets.only(
                            left: 16, right: 16, top: 12,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "myName replies to postAuthorName"
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _secondary,
                                    child: const Icon(Icons.person,
                                      color: Colors.white, size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.poppins(
                                          fontSize: 13, color: _textMain,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: myName,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const TextSpan(text: ' replies to '),
                                          TextSpan(
                                            text: postAuthorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13, color: _textMain,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Post your reply',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: const Color(0xFFABB8C3),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFE8E8E8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _sendReply(postAuthorName),
                                    child: Container(
                                      width: 42, height: 42,
                                      decoration: const BoxDecoration(
                                        color: _secondary, shape: BoxShape.circle,
                                      ),
                                      child: _isSending
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded,
                                              color: Colors.white, size: 18,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
