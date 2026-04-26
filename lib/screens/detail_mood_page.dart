import 'package:flutter/material.dart';
import '../models/mood.dart';

class DetailMoodPage extends StatelessWidget {
  final Mood mood;
  const DetailMoodPage({super.key, required this.mood});

  String getMoodImage(int i) {
    const list = [
      'assets/images/emot1.png',
      'assets/images/emot2.png',
      'assets/images/emot3.png',
      'assets/images/emot4.png',
      'assets/images/emot5.png',
    ];
    return list[(i >= 0 && i < list.length) ? i : 0];
  }

  String getEmotionImage(String e) {
    switch (e.toLowerCase()) {
      case 'happy': return 'assets/images/Happy.png';
      case 'sad': return 'assets/images/Sad.png';
      case 'angry': return 'assets/images/Angry.png';
      case 'stressed': return 'assets/images/Stressed.png';
      case 'tired': return 'assets/images/Tired.png';
      case 'relaxed': return 'assets/images/Relaxed.png';
      case 'grateful': return 'assets/images/Grateful.png';
      default: return 'assets/images/icon1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${mood.date.day.toString().padLeft(2, '0')}/${mood.date.month.toString().padLeft(2, '0')}/${mood.date.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFEAEA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5CBCB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9ECAD6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emoji + Photo Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji column
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF748DAE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        _circle(getMoodImage(mood.moodIndex), size: 48),
                        const SizedBox(height: 12),
                        _circle(getEmotionImage(mood.emotions.first), size: 36),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Photo box
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF9ECAD6), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF748DAE),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF9ECAD6), width: 1),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Journal section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF9ECAD6), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Journal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF748DAE),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF9ECAD6), width: 1),
                      ),
                      child: Text(
                        mood.note,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(String asset, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(6),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}