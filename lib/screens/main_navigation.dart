import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'mood_input_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const Center(child: Text('Community Page (Coming Soon)', style: TextStyle(fontSize: 20))),
    const Center(child: Text('Analytics Page (Coming Soon)', style: TextStyle(fontSize: 20))),
    const Center(child: Text('Profile Page (Coming Soon)', style: TextStyle(fontSize: 20))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],

      floatingActionButton: Transform.translate(
        offset: const Offset(0, 12),
        child: SizedBox(
          width: 80,
          height: 80,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MoodInputScreen()),
              );
            },
            backgroundColor: const Color(0xFFF3C4D3),
            elevation: 0,
            shape: const CircleBorder(),
            child: Image.asset(
              'assets/images/icon_plus.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomAppBar(
          color: const Color(0xFFA5C9D5),
          surfaceTintColor: Colors.transparent,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem('assets/images/icon_Home.png', 'Home', 0),
                _buildNavItem('assets/images/icon_Community.png', 'Community', 1),

                const SizedBox(width: 48),

                _buildNavItem('assets/images/icon_Analytics.png', 'Analytics', 2),
                _buildNavItem('assets/images/icon_Profile.png', 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {

    bool isSelected = _selectedIndex == index;

    Color itemColor = isSelected ? const Color(0xFF2D3748) : const Color(0xFF5A6A7E);

    return InkWell(
      onTap: () => _onItemTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: itemColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}