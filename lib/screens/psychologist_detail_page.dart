import 'package:flutter/material.dart';
import '../models/psychologist.dart';
import 'chat_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class PsychologistDetailPage extends StatelessWidget {
  final Psychologist psychologist;
  const PsychologistDetailPage({super.key, required this.psychologist});

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF9ECAD6);
    final Color secondaryBlue = const Color(0xFF748DAE);
    final Color accentPink = const Color(0xFFF5CBCB);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // AppBar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accentPink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset('assets/images/back.png'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Expert Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: secondaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentPink, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/doctor_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama
                    Text(
                      psychologist.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: secondaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      psychologist.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem(
                            Icons.work_outline,
                            '${psychologist.experience} Years',
                          ),
                          _infoItem(
                            Icons.star,
                            '${psychologist.rating} Rating',
                            starColor: true,
                          ),
                          _infoItem(
                            Icons.check_circle_outline,
                            '${psychologist.totalConsult}+ consult',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About
                    _sectionBox(
                      title: 'About',
                      child: Text(
                        psychologist.about,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Expertise
                    _sectionBox(
                      title: 'Expertise',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: psychologist.expertise
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: secondaryBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Education
                    _sectionBox(
                      title: 'Education & Credentials',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: psychologist.education
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Start Chat Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

                  final roomId = await ChatService.getOrCreateRoom(
                    userUid: userId,
                    psikologUid: psychologist.id,
                  );

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          roomId: roomId,
                          psikologUid: psychologist.id,
                          psikologName: psychologist.name,
                          psikologPhotoUrl: psychologist.photoUrl ?? '',
                        ),
                      ),
                    );
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPink,
                  foregroundColor: const Color(0xFF748DAE),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Chat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, {bool starColor = false}) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: starColor ? Colors.amber : const Color(0xFF748DAE),
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionBox({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9ECAD6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF748DAE),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
