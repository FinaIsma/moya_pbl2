import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io'; 
import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:http_parser/http_parser.dart'; 

class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({super.key});

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  int selectedMood = -1;
  int selectedEmotion = -1;
  DateTime selectedDate = DateTime.now();
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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

  List<String> getRecommendations(String emotion) {
    switch (emotion) {
      case "Happy":
      case "Grateful":
        return ["Share your joy with a friend", "Write down 3 things you're thankful for", "Treat yourself!"];
      case "Tired":
      case "Stressed":
        return ["Take a 15-minute power nap", "Listen to lo-fi music", "Deep breathing for 5 minutes"];
      case "Angry":
      case "Desperate":
        return ["Go for a quick walk", "Squeeze a stress ball", "Write out your frustrations on paper"];
      case "Sad":
        return ["Watch a comfort movie", "Hug a pillow", "Drink a warm cup of tea"];
      default:
        return ["Take a Deep Breath", "Drink some water", "Take a short break"];
    }
  }

  
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<void> saveMood() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (selectedMood == -1 || selectedEmotion == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select mood and emotion first")),
      );
      return;
    }

    if (journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a little bit about your day")),
      );
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    String? imageUrl;
    String emotionLabel = emotions[selectedEmotion]['label'];
    List<String> recommendations = getRecommendations(emotionLabel);

    try {
      if (_selectedImage != null) {
        imageUrl = await uploadToCloudinary(File(_selectedImage!.path));
      }

      await FirebaseFirestore.instance.collection('moods').add({
        'userId': userId,
        'date': selectedDate.toIso8601String(),
        'mood': selectedMood,
        'emotion': emotionLabel,
        'journal': journalController.text,
        'recommendations': recommendations,
        'photoUrl': imageUrl, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); 

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Image.asset(emotions[selectedEmotion]['icon'], width: 30),
                const SizedBox(width: 10),
                Expanded(child: Text("Saved! Since you're $emotionLabel...")),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: recommendations
                  .map((r) => ListTile(
                        leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                        title: Text(r, style: const TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  resetForm(); 
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error Detail: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void resetForm() {
    setState(() {
      selectedMood = -1;
      selectedEmotion = -1;
      selectedDate = DateTime.now();
      _selectedImage = null;
      journalController.clear();
    });
  }

  Future<void> pickDate() async {
    final DateTime today = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(today) ? today : selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  String formatDate(DateTime date) {
    return "${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)}";
  }

  String _getDayName(int day) {
    const days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[day];
  }

  String _getMonthName(int month) {
    const months = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: null, 
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // 1. AREA KONTEN UTAMA (BISA DI-SCROLL)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    // HEADER + TOMBOL BACK 
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFF7C8D8), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: cardBlue, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(formatDate(selectedDate), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: textBlue, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          const Text("How was your day?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: List.generate(moods.length, (index) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => selectedMood = index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: selectedMood == index ? Colors.white : Colors.transparent, 
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(
                                        moods[index], 
                                        width: 52, 
                                        height: 52, 
                                      ),
                                    ),
                                  ),
                                  if (index < moods.length - 1) const SizedBox(width: 10), 
                                ],
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
                      decoration: BoxDecoration(color: textBlue, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Emotions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: emotions.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.1,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: textBlue, 
                          width: 2.0,      
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's journal", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: textBlue, 
                                width: 1.5,      
                              ),
                            ),
                            child: TextField(
                              controller: journalController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: "Write here...",
                                hintStyle: TextStyle(color: textBlue.withOpacity(0.4), fontSize: 12),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: textBlue, 
                          width: 2.0,      
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's photo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: textBlue, 
                                  width: 1.5,      
                                ),
                              ),
                              child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!, 
                                          fit: BoxFit.cover, 
                                          width: double.infinity, 
                                          height: 150,
                                        );
                                      }
                                      return const Center(child: Icon(Icons.error, color: Colors.red));
                                    },
                                  ),
                                )
                              : const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 140), 
                  ],
                ),
              ),
            ),

            
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 34), 
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
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), 
                      side: const BorderSide(color: Colors.white, width: 2.0),
                    ),
                  ),
                  child: const Text("Done", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> uploadToCloudinary(File imageFile) async {
  String cloudName = "drkxaqn7z"; 
  String uploadPreset = "mooya_preset";

  try {
    var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    var request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'), 
    ));
    
    request.fields['upload_preset'] = uploadPreset;

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonRes = jsonDecode(responseString);
      return jsonRes['secure_url']; 
    }
  } catch (e) {
    print("Error Upload: $e");
  }
  return null;
}