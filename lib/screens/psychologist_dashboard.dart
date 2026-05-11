import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_psikolog_screen.dart';

class PsychologistDashboard extends StatefulWidget {
  const PsychologistDashboard({super.key});

  @override
  State<PsychologistDashboard> createState() => _PsychologistDashboardState();
}

class _PsychologistDashboardState extends State<PsychologistDashboard> {
  String _userName = "Loading..."; 
  String? _profileUrl; 

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userName = doc.data()!['name'] ?? "No Name"; 
          _profileUrl = doc.data()!['profileImage']; 
        });
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text('Sign out', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Are you sure you want to sign out?', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF748DAE), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      },
                      child: Text('Sign out', style: GoogleFonts.poppins(color: const Color(0xFFE07B7B), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9ECAD6))),
                      Text(_userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    ],
                  ),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFF5CBCB),
                        backgroundImage: _profileUrl != null ? NetworkImage(_profileUrl!) : null,
                        child: _profileUrl == null ? const Icon(Icons.person, color: Color(0xFF1A4A54)) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => _showSignOutDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFF2D3E50), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.logout, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Consultations', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1A4A54))),
              const SizedBox(height: 16),
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .where('psikolog_uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('last_message_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return Center(child: Text('No consultations found', style: GoogleFonts.poppins(color: Colors.grey)));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var chatData = docs[index].data() as Map<String, dynamic>;
                        int unread = chatData['unread_count'] ?? 0;
                        return GestureDetector(
                          onTap: () {
                            FirebaseFirestore.instance
                            .collection('chat_rooms')
                            .doc(docs[index].id)
                            .update({'unread_count': 0});
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoomPsikologScreen( 
                                  roomId: docs[index].id,
                                  userUid: chatData['user_uid'] ?? '',
                                  userName: chatData['user_name'] ?? 'User',
                                  userPhotoUrl: chatData['user_photo_url'] ?? 'https://via.placeholder.com/150',
                                ),
                              ),
                            );
                          },
                          child: _buildConsultationCard(
                            true, 
                            chatData['user_name'] ?? 'User',
                            chatData['last_message'] ?? 'No message yet',
                            chatData['last_message_at'] != null 
                                ? DateFormat('HH:mm').format((chatData['last_message_at'] as Timestamp).toDate()) 
                                : 'Just now',
                            unread,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard(bool isActive, String userName, String lastMsg, dynamic time, int unreadCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9ECAD6).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1A4A54)),
                ),
                Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF9ECAD6) : const Color(0xFFF5CBCB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Ended',
                    style: GoogleFonts.poppins(fontSize: 10, color: isActive ? const Color(0xFF1A4A54) : const Color(0xFFE07B7B), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time, 
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                
                if (unreadCount > 0)
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xFF9ECAD6),
                    child: Text('!', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}