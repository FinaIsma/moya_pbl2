import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await AuthHelper.setLoggedIn(false);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/opening');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Image.asset(
                'assets/images/icon1.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CBCB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt,
                    color: Color(0xFF748DAE),
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Hi, ${user?.displayName ?? 'User'}! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Dashboard coming soon...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5A6A7E),
                ),
              ),

              const SizedBox(height: 48),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAEA),
                      foregroundColor: const Color(0xFFE07B7B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
