import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'edit_profile_screen.dart';

// UBAH KE STATEFULWIDGET
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Konstanta Warna 
  static const Color darkTeal = Color(0xFF2C535D);
  static const Color lightGrey = Color(0xFFEDEDED);
  static const Color textGrey = Color(0xFF464646);
  static const Color softYellow = Color(0xFFFFE9BA);
  static const Color softPink = Color(0xFFF7C8D8);
  static const Color softBlue = Color(0xFF9ECAD6);
  static const Color deepTeal = Color(0xFF27464E);
  static const Color errorRed = Color(0xFFC44F4F);
  static const Color mediumTeal = Color(0xFF568491);

  // Variabel untuk simpan data user
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Ambil data pas halaman dibuka
  }

  // FUNGSI UNTUK AMBIL DATA DARI FIRESTORE
  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Personal Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkTeal),
              ),
              const SizedBox(height: 24),
              
              // Avatar Section 
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: softBlue, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 55,
                        // Ambil foto dari URL atau asset default
                        backgroundImage: (userData?['profileImage'] != null && userData!['profileImage'].toString().isNotEmpty)
                          ? NetworkImage("${userData!['profileImage']}?v=${DateTime.now().millisecondsSinceEpoch}")
                          : null,
                        child: (userData?['profileImage'] == null || userData!['profileImage'].toString().isEmpty)
                          ? const Icon(Icons.person, size: 45, color: Colors.white)
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          // 3. BAGIAN PENTING: Tunggu hasil dari EditProfileScreen
                          await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const EditProfileScreen())
                          );
                          // Begitu balik ke sini, panggil load data lagi
                          _loadUserData(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: deepTeal, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Section - DATA DIAMBIL DARI userData
              _buildSectionTitle('Profile'),
              _buildReadOnlyField('Full Name', userData?['fullName'] ?? '-'),
              _buildReadOnlyField('Nickname', userData?['nickname'] ?? '-'),
              _buildReadOnlyField('Date of Birth', userData?['dob'] ?? '-'),
              _buildReadOnlyField('Gender', userData?['gender'] ?? '-'),

              const SizedBox(height: 16),
              _buildSectionTitle('Contact'),
              _buildReadOnlyField('Email', FirebaseAuth.instance.currentUser?.email ?? '-'),

              const SizedBox(height: 16),
              _buildSectionTitle('Subscription'),
              // ... sisanya sama ...
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: softYellow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Basic Care (Free)', style: TextStyle(fontWeight: FontWeight.bold, color: textGrey)),
                    Icon(Icons.arrow_forward_ios, size: 16, color: textGrey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: darkTeal),
                  label: const Text('Sign Out', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: softPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pendukung tetap sama
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkTeal)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: lightGrey, borderRadius: BorderRadius.circular(12)),
        child: Text(value, style: const TextStyle(color: textGrey, fontSize: 14)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Log out', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal))),
        content: const Text('Are you sure you want to log out?', textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
        actions: [
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: mediumTeal)),
                ),
              ),
              const SizedBox(width: 1, height: 40, child: VerticalDivider()),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  child: const Text('Log out', style: TextStyle(color: errorRed)), 
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}