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
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Map<String, dynamic>> _allChats = [];
  bool _isLoadingChats = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _fetchChatRooms(); 
  }

  Future<void> _getUserData() async {
    if (_currentUid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('psychologists') 
          .doc(_currentUid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userName = doc.data()!['name'] ?? "No Name";
          
          String? rawUrl = doc.data()!['photoUrl']?.toString();
          if (rawUrl != null && rawUrl.trim().isNotEmpty) {
            _profileUrl = rawUrl.trim(); 
          } else {
            _profileUrl = null;
          }
        });
      }
    }
  }

  void _fetchChatRooms() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('psikolog_uid', isEqualTo: _currentUid)
        .snapshots()
        .listen((snapshot) async {

      List<Map<String, dynamic>> tempChats = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String userUid = data['user_uid'] ?? '';

        String patientName = "User";
        String patientPhoto = "";

        if (userUid.isNotEmpty) {
          try {
            var userDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
            if (userDoc.exists) {
              patientName = userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? "User";
              patientPhoto = userDoc.data()?['profileImage'] ?? userDoc.data()?['foto_profile'] ?? "";
            }
          } catch (e) {
            debugPrint("Gagal mengambil data user: $e");
          }
        }

        tempChats.add({
          'roomId': doc.id,
          'user_uid': userUid,
          'user_name': patientName,
          'user_photo_url': patientPhoto,
          'last_message': data['last_message'] ?? 'No message yet',
          'last_message_at': data['last_message_at'],
          'status': data['status'] ?? 'Active',
          'unread_psikolog': data['unread_psikolog'] ?? 0, 
        });
      }

      tempChats.sort((a, b) {
        Timestamp? timeA = a['last_message_at'];
        Timestamp? timeB = b['last_message_at'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _allChats = tempChats;
          _isLoadingChats = false;
        });
      }
    });
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
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5CBCB),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _profileUrl != null && _profileUrl!.isNotEmpty
                              ? Image.network(
                                  _profileUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, color: Color(0xFF1A4A54));
                                  },
                                )
                              : const Icon(Icons.person, color: Color(0xFF1A4A54)),
                        ),
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
              // Menampilkan List Chat
              Expanded(
                child: _isLoadingChats
                    ? const Center(child: CircularProgressIndicator())
                    : _allChats.isEmpty
                    ? Center(child: Text('No consultations found', style: GoogleFonts.poppins(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: _allChats.length,
                  itemBuilder: (context, index) {
                    var chatData = _allChats[index];
                    bool isActive = chatData['status'].toString().toLowerCase() == 'active';
                    String timeFormatted = chatData['last_message_at'] != null
                        ? DateFormat('HH:mm').format((chatData['last_message_at'] as Timestamp).toDate())
                        : 'Just now';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPsikologScreen(
                              roomId: chatData['roomId'],
                              userUid: chatData['user_uid'],
                              userName: chatData['user_name'],
                              userPhotoUrl: chatData['user_photo_url'],
                            ),
                          ),
                        );
                      },
                      child: _buildConsultationCard(
                        isActive,
                        chatData['user_name'],
                        chatData['last_message'],
                        timeFormatted,
                        chatData['user_photo_url'], 
                        chatData['unread_psikolog'] ?? 0,
                      ),
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

  Widget _buildConsultationCard(bool isActive, String userName, String lastMsg, String time, String userPhotoUrl, int unreadCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9ECAD6).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEBEBEB),
            backgroundImage: userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
            child: userPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1A4A54)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF82C89A) : const Color(0xFFF5CBCB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Ended',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF82C89A), 
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}