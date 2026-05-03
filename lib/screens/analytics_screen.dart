import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsScreen> {
  String _username = "User";
  bool isWeekly = true;
  bool isLoading = true;

  int weeklyDominantMoodIndex = -1;
  int weeklyDominantMoodCount = 0;
  double monthlyAvgScore = 0.0;
  double prevMonthAvgScore = 0.0;
  String weeklyBestDayName = "-"; 
  double weeklyBestDayScore = 0.0;
  int streakDays = 0;
  bool hasFilledToday = false;

  Map<int, double> weeklyScores = {};
  Map<int, double> monthlyScores = {};
  List<Map<String, dynamic>> weeklyTopEmotions = [];
  List<Map<String, dynamic>> monthlyTopEmotions = [];

  final List<String> moods = [
    "assets/images/emot1.png",
    "assets/images/emot2.png",
    "assets/images/emot3.png",
    "assets/images/emot4.png",
    "assets/images/emot5.png",
  ];

  final Map<String, String> emotionIcons = {
    "Happy": "assets/images/Happy.png",
    "Tired": "assets/images/Tired.png",
    "Angry": "assets/images/Angry.png",
    "Stressed": "assets/images/Stressed.png",
    "Relaxed": "assets/images/Relaxed.png",
    "Desperate": "assets/images/Desperate.png",
    "Sad": "assets/images/Sad.png",
    "Grateful": "assets/images/Grateful.png",
  };

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (userDoc.exists) _username = userDoc.get('name') ?? "User";

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime startOfPrevMonth = DateTime(now.year, now.month - 1, 1);

    var snapshot = await FirebaseFirestore.instance
        .collection('moods')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    List<QueryDocumentSnapshot> allMoods = snapshot.docs;

    _calculateStreak(allMoods, now);

    List<QueryDocumentSnapshot> currentWeekMoods = [];
    List<QueryDocumentSnapshot> currentMonthMoods = [];
    List<QueryDocumentSnapshot> prevMonthMoods = [];

    for (var doc in allMoods) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['date'] == null) continue;
      DateTime date = DateTime.parse(data['date']);

      if (date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek)) currentWeekMoods.add(doc);
      if (date.month == now.month && date.year == now.year) currentMonthMoods.add(doc);
      if (date.month == startOfPrevMonth.month && date.year == startOfPrevMonth.year) prevMonthMoods.add(doc);
    }

    _processStaticContainers(currentWeekMoods, currentMonthMoods, prevMonthMoods);

    _processChartAndEmotions(currentWeekMoods, currentMonthMoods, now);

    setState(() {
      isLoading = false;
    });
  }

  void _calculateStreak(List<QueryDocumentSnapshot> allMoods, DateTime now) {
    Set<String> filledDates = {};
    for (var doc in allMoods) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['date'] != null) {
        DateTime d = DateTime.parse(data['date']);
        filledDates.add(DateFormat('yyyy-MM-dd').format(d));
      }
    }

    String todayStr = DateFormat('yyyy-MM-dd').format(now);
    String yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    hasFilledToday = filledDates.contains(todayStr);

    if (!hasFilledToday && !filledDates.contains(yesterdayStr)) {
      streakDays = 0;
      return;
    }

    int streak = 0;
    DateTime checkDate = hasFilledToday ? now : now.subtract(const Duration(days: 1));

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      if (filledDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    streakDays = streak;
  }

  void _processStaticContainers(List<QueryDocumentSnapshot> weekly, List<QueryDocumentSnapshot> monthly, List<QueryDocumentSnapshot> prevMonthly) {
    Map<int, int> weeklyMoodCounts = {};
    for (var doc in weekly) {
      int m = doc['mood'];
      weeklyMoodCounts[m] = (weeklyMoodCounts[m] ?? 0) + 1;
    }
    weeklyDominantMoodIndex = -1;
    weeklyDominantMoodCount = 0;
    weeklyMoodCounts.forEach((key, val) {
      if (val > weeklyDominantMoodCount) {
        weeklyDominantMoodCount = val;
        weeklyDominantMoodIndex = key;
      }
    });

    monthlyAvgScore = _calculateAverage(monthly);
    prevMonthAvgScore = _calculateAverage(prevMonthly);

    Map<int, List<double>> weeklyScorePerDay = {};
    for (var doc in weekly) {
      DateTime d = DateTime.parse(doc['date']);
      double s = (5 - (doc['mood'] as int)).toDouble();
      if (!weeklyScorePerDay.containsKey(d.weekday)) weeklyScorePerDay[d.weekday] = [];
      weeklyScorePerDay[d.weekday]!.add(s);
    }

    double maxAvg = -1.0;
    int maxInputs = -1;
    int bestDayKey = -1;

    for (int i = 1; i <= 7; i++) {
      if (weeklyScorePerDay.containsKey(i)) {
        List<double> scores = weeklyScorePerDay[i]!;
        double avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg > maxAvg || (avg == maxAvg && scores.length > maxInputs)) {
          maxAvg = avg;
          maxInputs = scores.length;
          bestDayKey = i;
        }
      }
    }

    if (bestDayKey != -1) {
      weeklyBestDayScore = maxAvg;
      weeklyBestDayName = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"][bestDayKey - 1];
    } else {
      weeklyBestDayName = "-";
      weeklyBestDayScore = 0.0;
    }
  }

  void _processChartAndEmotions(List<QueryDocumentSnapshot> weekly, List<QueryDocumentSnapshot> monthly, DateTime now) {
    weeklyScores.clear();
    Map<int, List<double>> wScorePerDay = {};
    for (var doc in weekly) {
      DateTime d = DateTime.parse(doc['date']);
      double s = (5 - (doc['mood'] as int)).toDouble();
      if (!wScorePerDay.containsKey(d.weekday)) wScorePerDay[d.weekday] = [];
      wScorePerDay[d.weekday]!.add(s);
    }
    for (int i = 1; i <= 7; i++) {
      if (wScorePerDay.containsKey(i)) {
        weeklyScores[i] = wScorePerDay[i]!.reduce((a, b) => a + b) / wScorePerDay[i]!.length;
      } else {
        weeklyScores[i] = 0.0;
      }
    }

    monthlyScores.clear();
    Map<int, List<double>> mScorePerDay = {};
    for (var doc in monthly) {
      DateTime d = DateTime.parse(doc['date']);
      double s = (5 - (doc['mood'] as int)).toDouble();
      if (!mScorePerDay.containsKey(d.day)) mScorePerDay[d.day] = [];
      mScorePerDay[d.day]!.add(s);
    }
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      if (mScorePerDay.containsKey(i)) {
        monthlyScores[i] = mScorePerDay[i]!.reduce((a, b) => a + b) / mScorePerDay[i]!.length;
      } else {
        monthlyScores[i] = 0.0;
      }
    }

    weeklyTopEmotions = _calculateTopEmotions(weekly);
    monthlyTopEmotions = _calculateTopEmotions(monthly);
  }

  List<Map<String, dynamic>> _calculateTopEmotions(List<QueryDocumentSnapshot> data) {
    if (data.isEmpty) return [];
    Map<String, int> counts = {};
    for (var doc in data) {
      String e = doc['emotion'] ?? 'Unknown';
      counts[e] = (counts[e] ?? 0) + 1;
    }
    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < sorted.length && i < 4; i++) {
      result.add({
        "label": sorted[i].key,
        "percentage": (sorted[i].value / data.length) * 100,
        "icon": emotionIcons[sorted[i].key] ?? "assets/images/Happy.png",
      });
    }
    return result;
  }

  double _calculateAverage(List<QueryDocumentSnapshot> data) {
    if (data.isEmpty) return 0.0;
    double total = 0;
    for (var doc in data) {
      total += (5 - (doc.get('mood') as int)).toDouble();
    }
    return total / data.length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hi, ${_username.split(' ').first}", style: const TextStyle(fontSize: 28, color: Color(0xFF2D3748))),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 28, color: Color(0xFF2D3748)),
                  children: [
                    TextSpan(text: "Here is your "),
                    TextSpan(text: "summary", style: TextStyle(color: Color(0xFF748DAE), fontWeight: FontWeight.bold)),
                    TextSpan(text: "."),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.25,
                children: [
                  _buildDominantMood(),
                  _buildAverageScore(),
                  _buildBestDay(),
                  _buildStreak(),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Categories", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildToggleButton("Weekly", isWeeklyBtn: true),
                  const SizedBox(width: 12),
                  _buildToggleButton("Monthly", isWeeklyBtn: false),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isWeekly ? "This Week Moods" : "This Month Moods", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isWeekly ? const Color(0xFFF7C8D8) : const Color(0xFF82C89A), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              isWeekly ? "Current Week" : DateFormat('MMMM yyyy').format(DateTime.now()),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3C3C3C))
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: isWeekly ? _buildWeeklyChart() : _buildMonthlyChart(),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isWeekly ? "This Week Emotions" : "This Month Emotions", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Builder(
                        builder: (context) {
                          List<Map<String, dynamic>> currentTop = isWeekly ? weeklyTopEmotions : monthlyTopEmotions;
                          if (currentTop.isEmpty) return const Text("Not enough data yet.", style: TextStyle(color: Color(0xFF9E9E9E)));
                          return Column(
                            children: currentTop.map((emo) => _buildEmotionRow(emo["icon"], emo["percentage"])).toList(),
                          );
                        }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDominantMood() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF748DAE), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Dominant Mood", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("of Current Week", style: TextStyle(color: Colors.white70, fontSize: 12)),
          
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: weeklyDominantMoodIndex != -1
                  ? Image.asset(moods[weeklyDominantMoodIndex], width: 70)
                  : Image.asset('assets/images/emot0.png', width: 70),
            ),
          ),
          
          Text(
            weeklyDominantMoodIndex != -1 ? "$weeklyDominantMoodCount inputs" : "No data yet", 
            style: const TextStyle(color: Colors.white70, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildAverageScore() {
    double diff = monthlyAvgScore - prevMonthAvgScore;
    String sign = diff >= 0 ? "+" : "";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF9ECAD6), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/icon_avg.png', width: 35),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Average Score", style: TextStyle(color: Color(0xFF3C3C3C), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                      children: [
                        TextSpan(text: monthlyAvgScore.toStringAsFixed(1), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF3C3C3C))),
                        const TextSpan(text: " / 5", style: TextStyle(fontSize: 30, color: Color(0xFF3C3C3C))),
                      ]
                  ),
                ),
                Text("$sign${diff.toStringAsFixed(1)} vs Last Month", style: const TextStyle(color: Color(0xFF3C3C3C), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBestDay() {
    return Container(
      padding: const EdgeInsets.all(19), 
      decoration: BoxDecoration(color: const Color(0xFF55AC68).withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          weeklyBestDayName != "-"
              ? Image.asset('assets/images/icon_$weeklyBestDayName.png', width: 60)
              : Image.asset('assets/images/icon_noday.png', width: 60),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Best Day", style: TextStyle(color: Color(0xFF3C3C3C), fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  weeklyBestDayName != "-" ? "avg ${weeklyBestDayScore.toStringAsFixed(1)} / 5" : "No data yet", 
                  style: const TextStyle(color: Colors.white, fontSize: 12)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStreak() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFFFF099), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: hasFilledToday
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.asset('assets/images/icon_streak.png', width: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Streak", style: TextStyle(color: Colors.black87.withOpacity(hasFilledToday ? 0.75 : 0.5), fontWeight: FontWeight.bold, fontSize: 18)),
                Text("$streakDays Days", style: TextStyle(color: Colors.black87.withOpacity(hasFilledToday ? 0.75 : 0.5), fontWeight: FontWeight.bold, fontSize: 30)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, {required bool isWeeklyBtn}) {
    bool isActive = isWeekly == isWeeklyBtn;

    Color baseColor = isWeeklyBtn ? const Color(0xFFF7C8D8) : const Color(0xFF82C89A);
    Color borderColor = isActive
        ? (isWeeklyBtn ? const Color(0xFFD694A8) : const Color(0xFF55AC68))
        : Colors.transparent;
    Color textColor = const Color(0xFF3C3C3C);

    return GestureDetector(
      onTap: () {
        if (isWeekly != isWeeklyBtn) {
          setState(() {
            isWeekly = isWeeklyBtn;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  Widget _buildEmotionRow(String iconPath, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 12),
          SizedBox(
              width: 35,
              child: Text("${percentage.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF9ECAD6),
                minHeight: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5.5, 
        minY: 0,  
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();

                int score = value.toInt();
                if (score >= 1 && score <= 5) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(moods[5 - score], width: 20, height: 20),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (index) {
          double score = weeklyScores[index + 1] ?? 0.0;
          return BarChartGroupData(
            x: index + 1,
            barRods: [
              BarChartRodData(
                  toY: score == 0.0 ? 0.0 : score, 
                  color: const Color(0xFF9ECAD6),
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 5.0,
                    color: Colors.grey.shade100,
                  )
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    int daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    return Row(
      children: [
        SizedBox(
          width: 32, 
          child: LineChart(
            LineChartData(
              minX: 0, maxX: 1,
              minY: 0, maxY: 5.5, 
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.transparent, width: 2),
                    top: BorderSide.none, left: BorderSide.none, right: BorderSide.none,
                  )
              ),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [FlSpot(0, 0)], 
                  color: Colors.transparent,
                  barWidth: 0,
                  dotData: const FlDotData(show: false),
                )
              ],
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {  
                      if (value % 1 != 0) return const SizedBox.shrink();

                      int score = value.toInt();
                      if (score >= 1 && score <= 5) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.asset(moods[5 - score], width: 20, height: 20),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30, 
                    getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: daysInMonth * 25.0,
              child: LineChart(
                LineChartData(
                  minX: 0.5,
                  maxX: daysInMonth.toDouble() + 0.5,
                  minY: 0,
                  maxY: 5.5, 
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF748DAE), width: 2), 
                        top: BorderSide.none, left: BorderSide.none, right: BorderSide.none,
                      )
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();

                          int day = value.toInt();
                          if (day >= 1 && day <= daysInMonth) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(day.toString(), style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(daysInMonth, (index) {
                        int day = index + 1;
                        double score = monthlyScores[day] ?? 0.0;
                        return FlSpot(day.toDouble(), score);
                      }),
                      isCurved: false,
                      color: const Color(0xFF9ECAD6),
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) => spot.y != 0.0, 
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF9ECAD6),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}