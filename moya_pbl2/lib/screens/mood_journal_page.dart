import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../widgets/mood_card.dart';

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

  List<Mood> moods = [
    Mood(
      time: '21.12',
      emotion: 'Happy',
      note: 'Hari yang menyenangkan di tempat kerja, proyek selesai...',
      date: DateTime.now(),
    ),
    Mood(
      time: '12.00',
      emotion: 'Happy',
      note: 'Hari yang menyenangkan di tempat kerja, proyek selesai...',
      date: DateTime.now(),
    ),
    Mood(
      time: '17.00',
      emotion: 'Tired',
      note: 'Hari yang menyenangkan di tempat kerja, proyek selesai...',
      date: DateTime(2026, 4, 5),
    ),
    Mood(
      time: '09.50',
      emotion: 'Happy',
      note: 'Hari yang menyenangkan di tempat kerja, proyek selesai...',
      date: DateTime(2026, 4, 5),
    ),
    Mood(
      time: '22.30',
      emotion: 'Calm',
      note: 'Hari yang menyenangkan di tempat kerja, proyek selesai...',
      date: DateTime(2026, 4, 4),
    ),
  ];

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

  List<Mood> get filteredMoods {
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
    } else if (selectedFilter == 'This Month') {
      return moods
          .where((m) => m.date.month == now.month && m.date.year == now.year)
          .toList();
    }
    return moods;
  }

  Map<String, List<Mood>> get groupedMoods {
    final Map<String, List<Mood>> map = {};
    final now = DateTime.now();
    for (var mood in filteredMoods) {
      String label;
      if (mood.date.year == now.year &&
          mood.date.month == now.month &&
          mood.date.day == now.day) {
        label = 'Today';
      } else {
        final days = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday',
          'Friday', 'Saturday', 'Sunday',
        ];
        final months = [
          'January', 'February', 'March', 'April',
          'May', 'June', 'July', 'August',
          'September', 'October', 'November', 'December',
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  ...groupedMoods.entries.map(
                    (entry) => _buildSection(entry.key, entry.value),
                  ),
                ],
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
              child: Image.asset(
                'assets/images/back.png',
                width: 20,
                height: 20,
              ),
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
            (f) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedFilter = f;
                  selectedDate = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15, 
                    vertical: 7,    
                  ),
                  decoration: BoxDecoration(
                    color: selectedFilter == f && selectedDate == null
                        ? secondaryBlue
                        : primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w600,
                      fontSize: 12, // ✅ dikecilkan dari 13
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          if (selectedDate != null) ...[
            GestureDetector(
              onTap: () => setState(() => selectedDate = null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: secondaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year.toString().substring(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12, 
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Tombol kalender
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: 32, 
              height: 32,
              decoration: BoxDecoration(
                color: selectedDate != null ? secondaryBlue : primaryBlue,
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
              child: Image.asset('assets/images/note.png', fit: BoxFit.contain),
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