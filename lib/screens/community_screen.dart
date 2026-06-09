import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../helpers/display_name_helper.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currentUser = FirebaseAuth.instance.currentUser;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Future<void> _toggleLike(String postId, List likes) async {
    final uid = _currentUser?.uid ?? '';
    final ref = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(postId);
    if (likes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Delete Post?',
          style: GoogleFonts.poppins(
            fontSize: 17, fontWeight: FontWeight.w700, color: _textMain,
          ),
        ),
        content: Text('This post will be deleted permanently.',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
              style: GoogleFonts.poppins(fontSize: 14, color: _textSub),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(0xFFE07B7B),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(postId)
          .delete();
    }
  }

  // ─── Post Card ───────────────────────────────────────────────
  Widget _buildPostCard(DocumentSnapshot doc, {bool showDelete = false}) {
    final data   = doc.data() as Map<String, dynamic>;
    final postId = doc.id;
    final uid    = data['uid'] as String? ?? '';
    final likes  = List.from(data['likes'] ?? []);
    final liked  = likes.contains(_currentUser?.uid ?? '');
    final ts     = data['createdAt'] as Timestamp?;
    final isOwn  = DisplayNameHelper.isCurrentUser(uid);

    return FutureBuilder<String>(
      future: DisplayNameHelper.getDisplayName(uid),
      builder: (context, nameSnap) {
        final displayName = nameSnap.data ?? (isOwn ? 'You' : 'Anonymous...');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + username + time ──
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isOwn
                      ? _secondary
                      : _getAvatarColor(uid),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _textMain,
                            ),
                          ),
                          // Badge "You" kalau post sendiri
                          if (isOwn) ...[
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
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: _secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(_formatTime(ts),
                        style: GoogleFonts.poppins(
                          fontSize: 10, color: _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button — hanya di My Posts
                if (showDelete)
                  GestureDetector(
                    onTap: () => _deletePost(postId),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAEA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE07B7B), size: 18,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Content card — tap untuk buka detail ──
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: postId),
                ),
              ),
child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(0xFFFCFDFE),
                      ],
                    ),

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE9EEF2),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(data['content'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12, color: _textMain, height: 1.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Like + Reply ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(postId, likes),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(liked),
                          color: liked
                              ? const Color(0xFFFF6B81)
                              : const Color(0xFFABB8C3),
                          size: 22,
                        ),
                      ),
                      if (likes.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(_formatLikes(likes.length),
                          style: GoogleFonts.poppins(
                            fontSize: 12, color: _textSub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Reply button → buka detail
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: postId),
                    ),
                  ),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _secondary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: _secondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

        const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  // ─── All Posts ───────────────────────────────────────────────
  Widget _buildAllPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 60, color: _accent),
                const SizedBox(height: 12),
                Text('No post yet.',
                  style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                ),
                Text('Be the First to Share!',
                  style: GoogleFonts.poppins(fontSize: 12, color: _textSub),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildPostCard(docs[i]),
        );
      },
    );
  }

  // ─── My Posts ────────────────────────────────────────────────
  Widget _buildMyPosts() {
    final uid = _currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note_outlined, size: 60, color: _accent),
                const SizedBox(height: 12),
                Text('You don\'t have any posts yet.',
                  style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                ),
                const SizedBox(height: 4),
                Text('Tap ✏️ to start sharing.',
                  style: GoogleFonts.poppins(fontSize: 13, color: _textSub),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildPostCard(docs[i], showDelete: true),
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
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/icon1.png',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Community',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _textMain,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        'Safe Place to Share your Feelings',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Bar ──────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w400,
              ),
              labelColor: _textMain,
              unselectedLabelColor: _textSub,
              indicatorColor: _primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'All Posts'),
                Tab(text: 'My Posts'),
              ],
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      "assets/images/bg_chat.png",
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.03,
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllPosts(),
                    _buildMyPosts(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // FAB hanya muncul di tab My Posts
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreatePostScreen(),
          ),
        ),
        backgroundColor: _secondary,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
