import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/psychologist.dart';
import '../widgets/psychologist_card.dart';
import 'psychologist_detail_page.dart';

class PsychologistListPage extends StatefulWidget {
  const PsychologistListPage({super.key});

  @override
  State<PsychologistListPage> createState() => _PsychologistListPageState();
}

class _PsychologistListPageState extends State<PsychologistListPage> {
  final Color primaryBlue = const Color(0xFF9ECAD6);
  final Color secondaryBlue = const Color(0xFF748DAE);
  final Color accentPink = const Color(0xFFF5CBCB);

  String? selectedExpertise;
  String? selectedExperience;
  String? selectedGender;
  Map<String, dynamic>? selectedPriceRange;

  final List<String> expertiseList = [
    "Anxiety",
    "Depression",
    "Parenting",
    "Behavior",
  ];

  final List<Map<String, dynamic>> priceRanges = [
    {'label': '< Rp50.000', 'min': 0, 'max': 50000},
    {'label': 'Rp50.000 - Rp100.000', 'min': 50000, 'max': 100000},
    {'label': '> Rp100.000', 'min': 100000, 'max': 999999999},
  ];

  Stream<List<Psychologist>> getPsychologistStream() {
    return FirebaseFirestore.instance
        .collection('psychologists')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Psychologist.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  List<Psychologist> filterList(List<Psychologist> list) {
    if (selectedExpertise != null && selectedExpertise!.isNotEmpty) {
      list = list.where((p) => p.expertise.contains(selectedExpertise)).toList();
    }
    if (selectedGender != null && selectedGender!.isNotEmpty) {
      list = list.where((p) => p.gender == selectedGender).toList();
    }
    if (selectedExperience != null && selectedExperience!.isNotEmpty) {
      final exp = int.tryParse(selectedExperience!) ?? 0;
      list = list.where((p) => p.experience >= exp).toList();
    }
    if (selectedPriceRange != null) {
      list = list.where((p) =>
        p.price >= selectedPriceRange!['min'] &&
        p.price <= selectedPriceRange!['max']
      ).toList();
    }
    return list;
  }

  void _showExpertiseFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Expertise',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: secondaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('All', style: GoogleFonts.poppins()),
                leading: Radio<String?>(
                  value: null,
                  groupValue: selectedExpertise,
                  activeColor: secondaryBlue,
                  onChanged: (val) {
                    setState(() => selectedExpertise = val);
                    Navigator.pop(context);
                  },
                ),
              ),
              ...expertiseList.map((e) => ListTile(
                    title: Text(e, style: GoogleFonts.poppins()),
                    leading: Radio<String?>(
                      value: e,
                      groupValue: selectedExpertise,
                      activeColor: secondaryBlue,
                      onChanged: (val) {
                        setState(() => selectedExpertise = val);
                        Navigator.pop(context);
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showExperienceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Experience',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: secondaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('All', style: GoogleFonts.poppins()),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedExperience,
                activeColor: secondaryBlue,
                onChanged: (val) {
                  setState(() => selectedExperience = val);
                  Navigator.pop(context);
                },
              ),
            ),
            ...['3', '5', '8', '10'].map((e) => ListTile(
                  title: Text('$e+ Years', style: GoogleFonts.poppins()),
                  leading: Radio<String?>(
                    value: e,
                    groupValue: selectedExperience,
                    activeColor: secondaryBlue,
                    onChanged: (val) {
                      setState(() => selectedExperience = val);
                      Navigator.pop(context);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showGenderFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Gender',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: secondaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('All', style: GoogleFonts.poppins()),
              leading: Radio<String?>(
                value: null,
                groupValue: selectedGender,
                activeColor: secondaryBlue,
                onChanged: (val) {
                  setState(() => selectedGender = val);
                  Navigator.pop(context);
                },
              ),
            ),
            ...['Male', 'Female'].map((g) => ListTile(
                  title: Text(g, style: GoogleFonts.poppins()),
                  leading: Radio<String?>(
                    value: g,
                    groupValue: selectedGender,
                    activeColor: secondaryBlue,
                    onChanged: (val) {
                      setState(() => selectedGender = val);
                      Navigator.pop(context);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Price',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: secondaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('All', style: GoogleFonts.poppins()),
              leading: Radio<Map<String, dynamic>?>(
                value: null,
                groupValue: selectedPriceRange,
                activeColor: secondaryBlue,
                onChanged: (val) {
                  setState(() => selectedPriceRange = val);
                  Navigator.pop(context);
                },
              ),
            ),
            ...priceRanges.map((r) => ListTile(
                  title: Text(r['label'], style: GoogleFonts.poppins()),
                  leading: Radio<Map<String, dynamic>?>(
                    value: r,
                    groupValue: selectedPriceRange,
                    activeColor: secondaryBlue,
                    onChanged: (val) {
                      setState(() => selectedPriceRange = val);
                      Navigator.pop(context);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                    'Recommended Experts',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Filter row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _filterChip(
                    'Expertise',
                    selected: selectedExpertise != null,
                    onTap: _showExpertiseFilter,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    'Experience',
                    selected: selectedExperience != null,
                    onTap: _showExperienceFilter,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    'Gender',
                    selected: selectedGender != null,
                    onTap: _showGenderFilter,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    'Price',
                    selected: selectedPriceRange != null,
                    onTap: _showPriceFilter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: StreamBuilder<List<Psychologist>>(
                stream: getPsychologistStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada psikolog tersedia',
                        style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                    );
                  }

                  final list = filterList(snapshot.data!);

                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada psikolog dengan filter ini',
                        style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return PsychologistCard(
                        psychologist: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PsychologistDetailPage(psychologist: p),
                          ),
                        ),
                        onChat: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PsychologistDetailPage(psychologist: p),
                          ),
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
    );
  }

  Widget _filterChip(String label,
      {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? secondaryBlue : primaryBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: selected ? Colors.white : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}