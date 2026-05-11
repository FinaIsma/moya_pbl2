import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mood_journal_page.dart';
import 'psychologist_list_page.dart';
import 'share_report_screen.dart';
import 'chat_room_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isThingsToDoExpanded = false;
  String _username = " ";
  String? _profileImageUrl;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Map<int, int> _dailyMoods = {}; 
  Map<int, String> _dailyEmotions = {}; 
  String _todayEmotion = "";

  StreamSubscription? _moodsSubscription;
  StreamSubscription? _userSubscription; 

  @override
  void initState() {
    super.initState();
    _listenToUserData(); 
    _listenToMonthlyMoods(); 
  }

  @override
  void dispose() {
    _moodsSubscription?.cancel(); 
    _userSubscription?.cancel(); 
    super.dispose();
  }

  void _listenToUserData() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists && mounted) {
        setState(() {
          _username = userDoc.get('name') ?? "User";

          final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            _profileImageUrl = data['profileImage'] as String?;
          }
        });
      }
    }, onError: (error) {
      debugPrint("Error fetching user data: $error");
      if (mounted) {
        setState(() {
          _username = "User";
        });
      }
    });
  }

  void _listenToMonthlyMoods() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _moodsSubscription?.cancel();

    _moodsSubscription = FirebaseFirestore.instance
        .collection('moods')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots() 
        .listen((snapshot) {
      
      Map<int, Map<String, dynamic>> tempMoods = {};
      DateTime now = DateTime.now();
      String tempTodayEmotion = "";
      Timestamp? latestTodayCreatedAt;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['date'] == null || data['mood'] == null) continue;

        DateTime moodDate = DateTime.parse(data['date']);
        Timestamp? createdAt = data['createdAt'] as Timestamp?;
        int moodIndex = data['mood']; 
        String emotionLabel = data['emotion'] ?? ""; 

        if (moodDate.year == now.year && moodDate.month == now.month && moodDate.day == now.day) {
          if (latestTodayCreatedAt == null) {
            tempTodayEmotion = emotionLabel;
            latestTodayCreatedAt = createdAt;
          } else if (createdAt != null && createdAt.compareTo(latestTodayCreatedAt) > 0) {
            tempTodayEmotion = emotionLabel;
            latestTodayCreatedAt = createdAt;
          }
        }

        if (moodDate.month == _selectedMonth && moodDate.year == _selectedYear) {
          int day = moodDate.day;
          if (!tempMoods.containsKey(day)) {
            tempMoods[day] = {'mood': moodIndex, 'emotion': emotionLabel, 'createdAt': createdAt};
          } else {
            Timestamp? existingCreatedAt = tempMoods[day]!['createdAt'];
            if (createdAt != null && existingCreatedAt != null) {
              if (createdAt.compareTo(existingCreatedAt) > 0) {
                tempMoods[day] = {'mood': moodIndex, 'emotion': emotionLabel, 'createdAt': createdAt};
              }
            } else if (createdAt != null) {
               tempMoods[day] = {'mood': moodIndex, 'emotion': emotionLabel, 'createdAt': createdAt};
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _dailyMoods.clear();
          _dailyEmotions.clear(); 
          tempMoods.forEach((key, value) {
            _dailyMoods[key] = value['mood'];
            _dailyEmotions[key] = value['emotion']; 
          });
          _todayEmotion = tempTodayEmotion; 
        });
      }
    });
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  List<Map<String, dynamic>> _getRecommendationsDetails(String emotion) {
    switch (emotion) {
      case "Happy":
      case "Grateful":
        return [
          {"icon": Icons.people_outline, "title": "Share your joy with a friend", "subtitle": "Send a nice message to someone."},
          {"icon": Icons.edit_note, "title": "Write down 3 things you're thankful for", "subtitle": "Acknowledge the good things."},
          {"icon": Icons.card_giftcard, "title": "Treat yourself!", "subtitle": "You deserve it today."}
        ];
      case "Tired":
      case "Stressed":
        return [
          {"icon": Icons.bedtime_outlined, "title": "Take a 15-minute power nap", "subtitle": "Rest your eyes for a bit."},
          {"icon": Icons.headphones_outlined, "title": "Listen to lo-fi music", "subtitle": "Calm your mind with soft beats."},
          {"icon": Icons.air, "title": "Deep breathing for 5 minutes", "subtitle": "Inhale calm, exhale stress."}
        ];
      case "Angry":
      case "Desperate":
        return [
          {"icon": Icons.directions_walk, "title": "Go for a quick walk", "subtitle": "Release that built-up energy."},
          {"icon": Icons.sports_baseball_outlined, "title": "Squeeze a stress ball", "subtitle": "Let out the tension safely."},
          {"icon": Icons.edit_document, "title": "Write out your frustrations on paper", "subtitle": "Pour your feelings onto the page."}
        ];
      case "Sad":
        return [
          {"icon": Icons.movie_creation_outlined, "title": "Watch a comfort movie", "subtitle": "Distract yourself with a favorite film."},
          {"icon": Icons.favorite_border, "title": "Hug a pillow", "subtitle": "Give yourself some physical comfort."},
          {"icon": Icons.emoji_food_beverage_outlined, "title": "Drink a warm cup of tea", "subtitle": "Soothe your body from the inside."}
        ];
      default: 
        return [
          {
            "icon": Icons.edit_calendar_outlined, 
            "title": "We haven't heard from you!", 
            "subtitle": "Take a quick pause. Log your first mood today and let's see how we can support you."
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildGreeting(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 24),
              _buildThingsToDo(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back,",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86B4C4),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _username,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86B4C4), width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFD3D3D3), 
            backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                ? NetworkImage(_profileImageUrl!) 
                : null,
            child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 30) 
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    String firstName = _username.trim().isNotEmpty ? _username.trim().split(' ').first : "";
    return SizedBox(
      height: 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 20,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: "Hi, $firstName\n"),
                    const TextSpan(
                      text: "Pause ",
                      style: TextStyle(
                        color: Color(0xFF86B4C4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: "for second.\nHow was "),
                    const TextSpan(
                      text: "your ",
                      style: TextStyle(
                        color: Color(0xFF86B4C4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: "day?"),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/images/icon2.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3C4D3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionButton('assets/images/icon_journal.png', "Journal", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MoodJournalPage()),
            );
          }),

          _actionButton('assets/images/icon_consult.png', "Consult", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PsychologistListPage()),
            );
          }),

          _actionButton('assets/images/icon_chat.png', "Chats", () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Text(
                  "Pilih Psikolog",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xFF9ECAD6),
                          child: Icon(Icons.person, color: Colors.white)),
                      title: Text("Andi Saputra", style: GoogleFonts.poppins(fontSize: 14)),
                      subtitle: Text("Psikolog Klinis", style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              roomId: "ww5JJ340dbvTZDLBry4b",
                              psikologUid: "uid_andi_saputra",
                              psikologName: "Andi Saputra",
                              psikologPhotoUrl: "",
                            ),
                          ),
                        ); 
                      }, 
                    ),
                    const Divider(),
                    
                    ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF5CBCB),
                          child: Icon(Icons.person, color: Colors.white)),
                      title: Text("Saskia Putri", style: GoogleFonts.poppins(fontSize: 14)),
                      subtitle: Text("Psikolog Konseling", style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              roomId: "fOCiBcqC30NDbXLxAvtC", 
                              psikologUid: "uid_saskia_putri",
                              psikologName: "Saskia Putri",
                              psikologPhotoUrl: "",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }), 

          _actionButton('assets/images/icon_report.png', "Share Report", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShareReportPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionButton(String imagePath, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMonthYearPicker(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF86B4C4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${_monthNames[_selectedMonth - 1]} $_selectedYear",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
      final List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      int daysInMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
      int firstWeekdayOfMonth = DateTime(_selectedYear, _selectedMonth, 1).weekday;
      int firstDayOffset = firstWeekdayOfMonth == 7 ? 0 : firstWeekdayOfMonth;
      int totalCells = firstDayOffset + daysInMonth;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFA5C9D5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              children: daysOfWeek.map((day) => Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                if (index < firstDayOffset) {
                  return const SizedBox();
                }

                int day = index - firstDayOffset + 1;
                
                bool hasMood = _dailyMoods.containsKey(day);
                int moodIndex = hasMood ? _dailyMoods[day]! : -1;

                return Column(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle,
                      ),
                      child: hasMood
                          ? Center(
                              child: Image.asset(
                                'assets/images/emot${moodIndex + 1}.png', 
                                width: 26, 
                                height: 26,
                                fit: BoxFit.contain,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$day",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

  Widget _buildThingsToDo() {
    List<Map<String, dynamic>> recommendations = _getRecommendationsDetails(_todayEmotion);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF75B97A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isThingsToDoExpanded = !_isThingsToDoExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Things To Do",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isThingsToDoExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_isThingsToDoExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F4E9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _recommendationCard(
                      rec["icon"],
                      rec["title"],
                      rec["subtitle"],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recommendationCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF75B97A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF75B97A), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () {
                      setStateDialog(() {
                        tempYear--;
                      });
                    },
                  ),
                  Text(
                    tempYear.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      setStateDialog(() {
                        tempYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    bool isSelected = tempMonth == (index + 1);
                    return InkWell(
                      onTap: () {
                        setStateDialog(() {
                          tempMonth = index + 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF86B4C4) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _monthNames[index].substring(0, 3),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = tempMonth;
                      _selectedYear = tempYear;
                    });
                    _listenToMonthlyMoods(); 
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3C4D3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Select",
                    style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String name;
  const PlaceholderPage({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          '$name Page\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF748DAE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}