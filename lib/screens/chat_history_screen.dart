import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_room_screen.dart'; 

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
    
    // Listener untuk fitur search lokal
    _searchController.addListener(() {
      _filterChats(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchChatRooms() {
    // Memantau collection chat_rooms milik user yang sedang login
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('user_uid', isEqualTo: _currentUid)
        .snapshots()
        .listen((snapshot) async {
      
      List<Map<String, dynamic>> tempChats = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String psikologUid = data['psikolog_uid'] ?? '';
        
        // Nilai Default jika data psikolog belum ketemu
        String psikologName = "Dr. Psikolog"; 
        String psikologPhoto = "";

        // Mengambil nama dan foto psikolog dari collection 'psychologists'
        if (psikologUid.isNotEmpty) {
          try {
            var psiDoc = await FirebaseFirestore.instance.collection('psychologists').doc(psikologUid).get();
            if (psiDoc.exists) {
              psikologName = psiDoc.data()?['name'] ?? "Dr. Psikolog";
              psikologPhoto = psiDoc.data()?['photoUrl'] ?? "";
            }
          } catch (e) {
            debugPrint("Gagal mengambil data psikolog: $e");
          }
        }

        tempChats.add({
          'roomId': doc.id,
          'psikolog_uid': psikologUid,
          'psikolog_name': psikologName,
          'psikolog_photo': psikologPhoto,
          'last_message_at': data['last_message_at'],
          'status': data['status'] ?? 'Active', 
          'unread_user': data['unread_user'] ?? 0, 
        });
      }

      // Menyortir chat secara lokal dari yang terbaru ke terlama
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
          _filterChats(_searchController.text);
          _isLoading = false;
        });
      }
    });
  }

  // Fungsi Filter Pencarian Lokal
  void _filterChats(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChats = List.from(_allChats);
      });
    } else {
      setState(() {
        _filteredChats = _allChats.where((chat) {
          final name = chat['psikolog_name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // Format Jam
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat('HH.mm').format(date); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 28.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7C8D8), // Pink
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            ),
          ),
        ),
        title: Text(
          'Chat',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                suffixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF9ECAD6), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF9ECAD6), width: 1.5),
                ),
              ),
            ),
          ),

          // --- LIST CHAT ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9ECAD6)))
                : _filteredChats.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? "Belum ada riwayat chat." : "Chat tidak ditemukan.",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          bool isActive = chat['status'].toString().toLowerCase() == 'active';
                          int unreadCount = chat['unread_user']; 

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: () {
                                // Masuk ke dalam chat room
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      roomId: chat['roomId'],
                                      psikologUid: chat['psikolog_uid'],
                                      psikologName: chat['psikolog_name'],
                                      psikologPhotoUrl: chat['psikolog_photo'],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF9ECAD6), width: 1),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // FOTO PROFIL
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFFF7C8D8),
                                      backgroundImage: chat['psikolog_photo'].toString().isNotEmpty
                                          ? NetworkImage(chat['psikolog_photo'])
                                          : null,
                                      child: chat['psikolog_photo'].toString().isEmpty
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // NAMA & STATUS
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2), // Menyeimbangkan posisi teks dengan foto
                                          Text(
                                            chat['psikolog_name'],
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: const Color(0xFF2D3748),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFF82C89A) : const Color(0xFFF7C8D8),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Ended',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Waktu & Badge
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            _formatTime(chat['last_message_at']),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
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
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}