import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/psychologist.dart';

class PsychologistCard extends StatelessWidget {
  final Psychologist psychologist;
  final VoidCallback onChat;
  final VoidCallback onTap;

  const PsychologistCard({
    super.key,
    required this.psychologist,
    required this.onChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9ECAD6), width: 1),
        ),
        child: Row(
          children: [
           
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF9ECAD6),
          backgroundImage:
              (psychologist.photoUrl != null &&
                      psychologist.photoUrl!.isNotEmpty)
                  ? NetworkImage(psychologist.photoUrl!)
                  : null,
          child:
              (psychologist.photoUrl == null ||
                      psychologist.photoUrl!.isEmpty)
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 34,
                    )
                  : null,
        ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    psychologist.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    psychologist.title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _badge(
                          Icons.work_outline,
                          '${psychologist.experience} Years',
                        ),
                        const SizedBox(width: 2),
                        _badge(null, psychologist.gender),
                        const SizedBox(width: 2),
                        _badge(null, 'Rp${_formatPrice(psychologist.price)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chat button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5CBCB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData? icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF748DAE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
