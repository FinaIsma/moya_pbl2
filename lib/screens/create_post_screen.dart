import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller  = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading    = false;

  static const _primary  = Color(0xFF9ECAD6);
  static const _accent   = Color(0xFFF5CBCB);
  static const _textMain = Color(0xFF1A1A2E);

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Simpan uid saja — nama ditentukan saat render
      await FirebaseFirestore.instance.collection('community_posts').add({
        'uid':       _currentUser?.uid ?? '',
        'content':   text,
        'likes':     [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal posting. Coba lagi.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFE07B7B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 16),

            // ── Text Area ────────────────────────────────────
Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _primary.withOpacity(0.25),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF5A6A7E),
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Posting secara anonim",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _textMain,
                  ),
                ),

                Text(
                  "Nama kamu tidak akan terlihat",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 18),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.7,
                color: _textMain,
              ),
              decoration: InputDecoration(
                hintText:
                    "Apa yang sedang kamu rasakan hari ini?\n\nKamu bisa berbagi cerita di sini...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  height: 1.6,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(22),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Text(
                "${_controller.text.length}/500",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      ],
    ),
  ),
),
            // ── Posting Button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: const Color(0xFF1A4A54),
                    elevation: 4,
                    shadowColor: _primary.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A4A54),
                            ),
                          )
                        : Text('Posting',
                            style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
