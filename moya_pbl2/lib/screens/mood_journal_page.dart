import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood.dart';
import '../widgets/mood_card.dart';
import 'package:intl/intl.dart';

class MoodJournalPage extends StatefulWidget {
  const MoodJournalPage({super.key});

  @override
  State<MoodJournalPage> createState() => _MoodJournalPageState();
}

class _MoodJournalPageState extends State<MoodJournalPage> {
  final Color primaryBlue = const Color(0xFF9ECAD6);
  final Color secondaryBlue = const Color(0xFF748DAE);
  final Color accentPink = const Color(0xFFF5CBCB);
  final Color bgColor = Colors.white;

  String selectedFilter = 'All';
  DateTime? selectedDate;
  final List<String> filters = ['All', 'This Week', 'This Month'];

  Stream<List<Mood>> getMoodStream() {
  return FirebaseFirestore.instance
      .collection('moods')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      DateTime parsedDate;
      try {
        parsedDate = DateTime.parse(data['date']);
      } catch (e) {
        parsedDate = DateTime.now(); 
      }

      return Mood(
        time: DateFormat.Hm().format(parsedDate), // 
        emotion: data['emotion'] ?? '',
        note: data['journal'] ?? '',
        date: parsedDate,
        moodIndex: data['moodIndex'] ?? 0,
      );
    }).toList();
  });
}

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedFilter = 'All';
      });
    }
  }

  List<Mood> filterData(List<Mood> moods) {
    final now = DateTime.now();

    if (selectedDate != null) {
      return moods
          .where(
            (m) =>
                m.date.year == selectedDate!.year &&
                m.date.month == selectedDate!.month &&
                m.date.day == selectedDate!.day,
          )
          .toList();
    }

    if (selectedFilter == 'This Week') {
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      return moods
          .where(
            (m) => m.date.isAfter(weekStart.subtract(const Duration(days: 1))),
          )
          .toList();
    }

    if (selectedFilter == 'This Month') {
      return moods
          .where((m) => m.date.month == now.month && m.date.year == now.year)
          .toList();
    }

    return moods;
  }

  Map<String, List<Mood>> groupData(List<Mood> moods) {
    final Map<String, List<Mood>> map = {};
    final now = DateTime.now();

    for (var mood in moods) {
      String label;

      if (mood.date.year == now.year &&
          mood.date.month == now.month &&
          mood.date.day == now.day) {
        label = 'Today';
      } else {
        final days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];

        label =
            '${days[mood.date.weekday - 1]}, ${months[mood.date.month - 1]} ${mood.date.day.toString().padLeft(2, '0')}';
      }

      map.putIfAbsent(label, () => []).add(mood);
    }

    return map;
  }

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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final moods = filterData(snapshot.data!);
                  final grouped = groupData(moods);

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    children: [
                      ...grouped.entries.map(
                        (entry) => _buildSection(entry.key, entry.value),
                      ),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
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
            'Mood Journal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: secondaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...filters.map(
            (f) => GestureDetector(
              onTap: () => setState(() {
                selectedFilter = f;
                selectedDate = null;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedFilter == f ? secondaryBlue : primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/images/calendar.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, List<Mood> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/images/note.png'),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: secondaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((m) => MoodCard(mood: m)),
      ],
    );
  }
}