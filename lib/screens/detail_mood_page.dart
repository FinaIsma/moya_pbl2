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
      case 'happy':
        return 'assets/images/Happy.png';
      case 'sad':
        return 'assets/images/Sad.png';
      case 'angry':
        return 'assets/images/Angry.png';
      case 'stressed':
        return 'assets/images/Stressed.png';
      case 'tired':
        return 'assets/images/Tired.png';
      case 'relaxed':
        return 'assets/images/Relaxed.png';
      case 'grateful':
        return 'assets/images/Grateful.png';
      default:
        return 'assets/images/icon1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${mood.date.day.toString().padLeft(2, '0')}/${mood.date.month.toString().padLeft(2, '0')}/${mood.date.year}';

    final bool hasPhoto = mood.photoUrl != null && mood.photoUrl!.isNotEmpty;

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

              // Emoji + Photo or Journal Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji column
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF748DAE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        _circle(getMoodImage(mood.moodIndex), size: 52),
                        const SizedBox(height: 12),
                        _circle(getEmotionImage(mood.emotions.first), size: 40),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF9ECAD6),
                          width: 1.2,
                        ),
                      ),
                      child: hasPhoto
                          ? Column(
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
                                      border: Border.all(
                                        color: const Color(0xFF9ECAD6),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: Colors.black,
                                              insetPadding: EdgeInsets.zero,
                                              child: Stack(
                                                children: [
                                                  InteractiveViewer(
                                                    child: Center(
                                                      child: Image.network(
                                                        mood.photoUrl!,
                                                        fit: BoxFit.contain,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 40,
                                                    right: 16,
                                                    child: GestureDetector(
                                                      onTap: () => Navigator.pop(
                                                        context,
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(
                                                          8,
                                                        ),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.white24,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Image.network(
                                          mood.photoUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.grey.shade400,
                                                size: 40,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
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
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F4F8),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF9ECAD6),
                                          width: 1,
                                        ),
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
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 20),
                // Journal section
                Container(
                  width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF9ECAD6),
                    width: 1.2,
                  ),
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
                        border: Border.all(
                          color: const Color(0xFF9ECAD6),
                          width: 1,
                        ),
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
              ]
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
