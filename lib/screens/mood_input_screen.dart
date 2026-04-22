import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({super.key});

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  int selectedMood = -1;
  int selectedEmotion = -1;
  DateTime selectedDate = DateTime.now();

  final TextEditingController journalController = TextEditingController();

  final Color bgColor     = const Color(0xFFF6F6F6);
  final Color cardPink    = const Color(0xFFF7C8D8); 
  final Color cardBlue    = const Color(0xFF9ECAD6); 
  final Color textBlue    = const Color(0xFF748DAE); 
  final Color buttonGreen = const Color(0xFF55AC68); 

  final List<String> moods = [
    "assets/images/emot1.png",
    "assets/images/emot2.png",
    "assets/images/emot3.png",
    "assets/images/emot4.png",
    "assets/images/emot5.png",
  ];

  final List<Map<String, dynamic>> emotions = [
    {"icon": "assets/images/Happy.png",     "label": "Happy"},
    {"icon": "assets/images/Tired.png",     "label": "Tired"},
    {"icon": "assets/images/Angry.png",     "label": "Angry"},
    {"icon": "assets/images/Stressed.png",  "label": "Stressed"},
    {"icon": "assets/images/Relaxed.png",   "label": "Relaxed"},
    {"icon": "assets/images/Desperate.png", "label": "Desperate"},
    {"icon": "assets/images/Sad.png",       "label": "Sad"},
    {"icon": "assets/images/Grateful.png",  "label": "Grateful"},
  ];

  @override
  void dispose() {
    journalController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  String formatDate(DateTime date) {
    return "${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)}";
  }

  String _getDayName(int day) {
    const days = ["", "Monday", "Tuesday", "Wednesday",
                  "Thursday", "Friday", "Saturday", "Sunday"];
    return days[day];
  }

  String _getMonthName(int month) {
    const months = ["", "January", "February", "March", "April",
      "May", "June", "July", "August", "September",
      "October", "November", "December"];
    return months[month];
  }

  Future<void> saveMood() async {
    if (selectedMood == -1 || selectedEmotion == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select mood and emotion first")),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('moods').add({
      'date':      selectedDate.toIso8601String(),
      'mood':      selectedMood,
      'emotion':   emotions[selectedEmotion]['label'],
      'journal':   journalController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // HEADER 
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7C8D8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Colors.black87, 
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: cardBlue, 
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formatDate(selectedDate),
                                    style: const TextStyle(
                                      color: Colors.black87, 
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // HOW WAS YOUR DAY 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: textBlue, 
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "How was your day?",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(moods.length, (index) {
                              return GestureDetector(
                                onTap: () => setState(() => selectedMood = index),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedMood == index ? Colors.white : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(moods[index], width: 32, height: 32),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // EMOTIONS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: textBlue, 
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Emotions",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: emotions.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final item = emotions[index];
                              final bool isSelected = selectedEmotion == index;
                              return GestureDetector(
                                onTap: () => setState(() => selectedEmotion = index),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(item["icon"], width: 24, height: 24),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(item["label"], style: const TextStyle(fontSize: 11, color: Colors.white)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TODAY'S JOURNAL 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: textBlue.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's journal", 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                          ),
                          const SizedBox(height: 10),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: textBlue.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: journalController,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: "Write here...",
                                hintStyle: TextStyle(
                                  color: textBlue.withOpacity(0.4), 
                                  fontSize: 12
                                ),
                                border: InputBorder.none, 
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TODAY'S PHOTO 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: textBlue.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Upload coming soon")),
                              );
                            },
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: textBlue.withOpacity(0.25)),
                              ),
                              child: const Center(child: Text("Add a photo", style: TextStyle(fontSize: 13))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- DONE BUTTON (DITARUH DI LUAR SCROLLVIEW SUPAYA TETAP DI BAWAH) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 35), 
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),    
                  topRight: Radius.circular(30),   
                ),
              ),
              child: ElevatedButton(
                onPressed: saveMood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), 
                    side: const BorderSide(color: Colors.white, width: 2.0),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}