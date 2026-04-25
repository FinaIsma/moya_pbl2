import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../screens/detail_mood_page.dart';

class MoodCard extends StatelessWidget {
  final Mood mood;
  const MoodCard({super.key, required this.mood});

  final Color primaryBlue = const Color(0xFF9ECAD6);

  String getMoodImage(int index) {
    const moodImages = [
      'assets/images/emot1.png',
      'assets/images/emot2.png',
      'assets/images/emot3.png',
      'assets/images/emot4.png',
      'assets/images/emot5.png',
    ];

    if (index < 0 || index >= moodImages.length) {
      return moodImages[0];
    }

    return moodImages[index];
  }

  
  String getEmotionImage(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'assets/images/Happy.png';
      case 'tired':
        return 'assets/images/Tired.png';
      case 'angry':
        return 'assets/images/Angry.png';
      case 'stressed':
        return 'assets/images/Stressed.png';
      case 'relaxed':
        return 'assets/images/Relaxed.png';
      case 'desperate':
        return 'assets/images/Desperate.png';
      case 'sad':
        return 'assets/images/Sad.png';
      case 'grateful':
        return 'assets/images/Grateful.png';
      default:
        return 'assets/images/Happy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailMoodPage(mood: mood),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryBlue, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                getMoodImage(mood.moodIndex),
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    children: [
                      const Text(
                        'Mood ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          mood.time,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  
                  Row(
                    children: [
                      Image.asset(
                        getEmotionImage(mood.emotion),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          mood.emotion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                 
                  Text(
                    mood.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/arrow_right.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}