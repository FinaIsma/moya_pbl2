import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood.dart';
import 'detail_mood_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MoodJournalPage extends StatefulWidget {
  const MoodJournalPage({super.key});

  @override
  State<MoodJournalPage> createState() => _MoodJournalPageState();
}

class _MoodJournalPageState extends State<MoodJournalPage> {
  final Color primaryBlue  = const Color(0xFF9ECAD6);
  final Color secondaryBlue = const Color(0xFF748DAE);
  final Color accentPink   = const Color(0xFFF5CBCB);
  final Color bgColor      = Colors.white;

  String selectedFilter = 'All';
  DateTime? selectedDate;
  final List<String> filters = ['All', 'This Week', 'This Month'];

  // ──────────────────────────────────────────
  // Helpers: image mapping
  // ──────────────────────────────────────────
  String _getMoodImage(int i) {
    const list = [
      'assets/images/emot1.png',
      'assets/images/emot2.png',
      'assets/images/emot3.png',
      'assets/images/emot4.png',
      'assets/images/emot5.png',
    ];
    return list[(i >= 0 && i < list.length) ? i : 0];
  }

  String _getEmotionImage(String e) {
    switch (e.toLowerCase()) {
      case 'happy':     return 'assets/images/Happy.png';
      case 'sad':       return 'assets/images/Sad.png';
      case 'angry':     return 'assets/images/Angry.png';
      case 'stressed':  return 'assets/images/Stressed.png';
      case 'tired':     return 'assets/images/Tired.png';
      case 'relaxed':   return 'assets/images/Relaxed.png';
      case 'grateful':  return 'assets/images/Grateful.png';
      case 'desperate': return 'assets/images/Desperate.png';
      default:          return 'assets/images/emot1.png';
    }
  }

  // ──────────────────────────────────────────
  // Stream
  // ──────────────────────────────────────────
  Stream<List<Mood>> getMoodStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('moods')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final moods = snapshot.docs.map((doc) {
            final data = doc.data();
            DateTime parsedDate;
            try {
              parsedDate = DateTime.parse(data['date']);
            } catch (e) {
              parsedDate = DateTime.now();
            }
            return Mood(
              time: DateFormat.Hm().format(parsedDate),
              emotions: [data['emotion'] ?? ''],
              note: data['journal'] ?? '',
              date: parsedDate,
              moodIndex: data['mood'] ?? 0,
              photoUrl: data['photoUrl'],
            );
          }).toList();

          moods.sort((a, b) => b.date.compareTo(a.date));
          return moods;
        });
  }

  // ──────────────────────────────────────────
  // Date picker
  // ──────────────────────────────────────────
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
            colorScheme: ColorScheme.light(
              primary: secondaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1A1A2E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: secondaryBlue,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedFilter = 'All';
      });
    }
  }

  // ──────────────────────────────────────────
  // Filter
  // ──────────────────────────────────────────
  List<Mood> filterData(List<Mood> moods) {
    final now = DateTime.now();

    if (selectedDate != null) {
      return moods
          .where((m) =>
              m.date.year  == selectedDate!.year &&
              m.date.month == selectedDate!.month &&
              m.date.day   == selectedDate!.day)
          .toList();
    }

    if (selectedFilter == 'This Week') {
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      return moods
          .where((m) => m.date.isAfter(weekStart.subtract(const Duration(days: 1))))
          .toList();
    }

    if (selectedFilter == 'This Month') {
      return moods
          .where((m) => m.date.month == now.month && m.date.year == now.year)
          .toList();
    }

    return moods;
  }

  // ──────────────────────────────────────────
  // Group by day
  // ──────────────────────────────────────────
  Map<String, List<Mood>> groupData(List<Mood> moods) {
    final Map<String, List<Mood>> map = {};
    final now = DateTime.now();

    for (var mood in moods) {
      String label;

      if (mood.date.year  == now.year &&
          mood.date.month == now.month &&
          mood.date.day   == now.day) {
        label = 'Today';
      } else {
        const days   = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'];
        label = '${days[mood.date.weekday]}, '
                '${months[mood.date.month]} '
                '${mood.date.day.toString().padLeft(2, '0')}';
      }

      map.putIfAbsent(label, () => []).add(mood);
    }
    return map;
  }

  // ──────────────────────────────────────────
  // Stats text  (point 8)
  // ──────────────────────────────────────────
  String _statsText(List<Mood> allMoods, List<Mood> filtered) {
    final now = DateTime.now();

    if (selectedDate != null) {
      final n = filtered.length;
      return '$n ${n == 1 ? 'entry' : 'entries'} on ${DateFormat('MMM d').format(selectedDate!)}';
    }

    if (selectedFilter == 'This Week') {
      final n = filtered.length;
      return '$n ${n == 1 ? 'entry' : 'entries'} this week';
    }

    if (selectedFilter == 'This Month') {
      final n = filtered.length;
      return '$n journals this month';
    }

    // 'All' — highlight today's count
    final todayCount = allMoods.where((m) =>
        m.date.year  == now.year &&
        m.date.month == now.month &&
        m.date.day   == now.day).length;

    if (todayCount > 0) {
      return '$todayCount ${todayCount == 1 ? 'entry' : 'entries'} today  •  ${allMoods.length} total';
    }

    return '${allMoods.length} total entries';
  }

  // ──────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildFilterRow(context),
            Expanded(
              child: StreamBuilder<List<Mood>>(
                stream: getMoodStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final allMoods = snapshot.data!;
                  final moods    = filterData(allMoods);
                  final grouped  = groupData(moods);
                  final entries  = grouped.entries.toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // ── Stats bar ──
                      _buildStatsBar(_statsText(allMoods, moods), moods.isEmpty),
                      const SizedBox(height: 12),

                      if (moods.isEmpty)
                        _buildEmptyFiltered()
                      else
                        for (var i = 0; i < entries.length; i++)
                          _buildSection(entries[i].key, entries[i].value, isFirst: i == 0),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // 1. App Bar  (title + subtitle)
  // ──────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 7. Arrow button — smaller, softer shadow
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentPink,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: accentPink.withOpacity(0.45),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black.withOpacity(0.55),
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mood Journal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Track your emotions every day',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 2. Filter row  (tight chips + calendar)
  // ──────────────────────────────────────────
  Widget _buildFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Chips
          ...filters.map((f) {
            final active = selectedFilter == f && selectedDate == null;
            return GestureDetector(
              onTap: () => setState(() {
                selectedFilter = f;
                selectedDate   = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? secondaryBlue : primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: secondaryBlue.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  child: Text(f),
                ),
              ),
            );
          }),
          const Spacer(),
          // Calendar button — same pill style as chips
          GestureDetector(
            onTap: () => _pickDate(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selectedDate != null ? secondaryBlue : primaryBlue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selectedDate != null
                    ? [
                        BoxShadow(
                          color: secondaryBlue.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 17,
                color: selectedDate != null ? Colors.white : Colors.black.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 8. Stats bar
  // ──────────────────────────────────────────
  Widget _buildStatsBar(String text, bool empty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, size: 16, color: secondaryBlue),
          const SizedBox(width: 8),
          Text(
            empty ? 'No entries found' : text,
            style: TextStyle(
              fontSize: 13,
              color: secondaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 3. Date divider section  ──── Today ────
  // ──────────────────────────────────────────
  Widget _buildSection(String label, List<Mood> items, {bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: secondaryBlue.withOpacity(0.22),
                thickness: 1,
                endIndent: 10,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryBlue.withOpacity(0.65),
                letterSpacing: 0.4,
              ),
            ),
            Expanded(
              child: Divider(
                color: secondaryBlue.withOpacity(0.22),
                thickness: 1,
                indent: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((m) => _buildMoodCard(m)),
      ],
    );
  }

  // ──────────────────────────────────────────
  // 4–7. Mood Card (replaces MoodCard widget)
  // ──────────────────────────────────────────
  Widget _buildMoodCard(Mood mood) {
    final emotion = mood.emotions.isNotEmpty ? mood.emotions.first : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailMoodPage(mood: mood)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // 6. Soft border + floating shadow
          border: Border.all(
            color: primaryBlue.withOpacity(0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 5. Emotion thumbnail — padded, rounded bg
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentPink.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                _getEmotionImage(emotion),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),

            // 4. Content: emotion label top-right time, journal below
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        emotion,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: secondaryBlue,
                        ),
                      ),
                      Text(
                        mood.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mood.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 7. Arrow — smaller, softer
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: secondaryBlue.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Empty states
  // ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined, size: 48, color: primaryBlue.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No mood entries yet',
            style: TextStyle(color: Color(0xFF748DAE)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFiltered() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No entries for this filter',
          style: TextStyle(color: secondaryBlue.withOpacity(0.55)),
        ),
      ),
    );
  }
}