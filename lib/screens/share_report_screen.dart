import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShareReportPage extends StatefulWidget {
  const ShareReportPage({super.key});

  @override
  State<ShareReportPage> createState() => _ShareReportPageState();
}

class _ShareReportPageState extends State<ShareReportPage> {
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  List<QueryDocumentSnapshot> moodDocs = [];
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      }

      DateTime thirtyDaysAgo = now.subtract(const Duration(days: 29));
      DateTime startOfThirtyDaysAgo = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);

      var snapshot = await FirebaseFirestore.instance
          .collection('moods')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      List<QueryDocumentSnapshot> validMoods = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['date'] != null) {
          DateTime d = DateTime.parse(data['date']);
          if (d.isAfter(startOfThirtyDaysAgo) || d.isAtSameMomentAs(startOfThirtyDaysAgo)) {
            validMoods.add(doc);
          }
        }
      }

      validMoods.sort((a, b) {
        DateTime d1 = DateTime.parse((a.data() as Map<String, dynamic>)['date']);
        DateTime d2 = DateTime.parse((b.data() as Map<String, dynamic>)['date']);
        return d1.compareTo(d2);
      });

      moodDocs = validMoods;
    } catch (e) {
      debugPrint("Error loading report data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    List<DateTime> last30Days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    String todayStr = DateFormat('dd MMMM yyyy').format(now);
    String periodStr = "${DateFormat('dd MMM yyyy').format(last30Days.first)} - $todayStr";

    final emot1 = (await rootBundle.load('assets/images/emot1.png')).buffer.asUint8List();
    final emot2 = (await rootBundle.load('assets/images/emot2.png')).buffer.asUint8List();
    final emot3 = (await rootBundle.load('assets/images/emot3.png')).buffer.asUint8List();
    final emot4 = (await rootBundle.load('assets/images/emot4.png')).buffer.asUint8List();
    final emot5 = (await rootBundle.load('assets/images/emot5.png')).buffer.asUint8List();

    Map<int, pw.MemoryImage> moodImages = {
      5: pw.MemoryImage(emot1),
      4: pw.MemoryImage(emot2),
      3: pw.MemoryImage(emot3),
      2: pw.MemoryImage(emot4),
      1: pw.MemoryImage(emot5),
    };

    Map<String, pw.MemoryImage> emotionImages = {};
    List<String> emoNames = ['Happy', 'Tired', 'Angry', 'Stressed', 'Relaxed', 'Desperate', 'Sad', 'Grateful'];
    for (String emo in emoNames) {
      try {
        final bytes = (await rootBundle.load('assets/images/$emo.png')).buffer.asUint8List();
        emotionImages[emo] = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint("Image $emo not found");
      }
    }

    List<pw.PointChartValue> chartPoints = [];
    for (int i = 0; i < 30; i++) {
      DateTime day = last30Days[i];
      var dayMoods = moodDocs.where((doc) {
        DateTime d = DateTime.parse((doc.data() as Map<String, dynamic>)['date']);
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();

      if (dayMoods.isNotEmpty) {
        double totalScore = 0;
        for (var doc in dayMoods) {
          int moodIndex = (doc.data() as Map<String, dynamic>)['mood'] as int;
          totalScore += (5 - moodIndex);
        }
        chartPoints.add(pw.PointChartValue((i + 1).toDouble(), totalScore / dayMoods.length));
      }
    }

    Map<String, int> emoCounts = {};
    for (var doc in moodDocs) {
      String emo = (doc.data() as Map<String, dynamic>)['emotion'] ?? 'Unknown';
      emoCounts[emo] = (emoCounts[emo] ?? 0) + 1;
    }
    var sortedEmos = emoCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top5 = sortedEmos.take(5).toList();

    int maxEmoCount = top5.isNotEmpty ? top5.first.value : 10;
    if (maxEmoCount < 5) maxEmoCount = 5;

    List<PdfColor> barColors = [
      const PdfColor.fromInt(0xFF1B4965),
      const PdfColor.fromInt(0xFF326A7C),
      const PdfColor.fromInt(0xFF62A2B2),
      const PdfColor.fromInt(0xFF9ECAD6),
      const PdfColor.fromInt(0xFFCBE5ED),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text("MOOD REPORT", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 30),

            pw.Text("I. Identity", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Name", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Gender", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Date of birth", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Report Generated On", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(": ${userData['fullName'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(": ${userData['gender'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(": ${userData['dob'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(": $todayStr", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text("II. Graphic Chart Mood", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text("Period: $periodStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 160,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: pw.FixedAxis(
                    List.generate(32, (i) => i.toDouble()),
                    ticks: true,
                    buildLabel: (v) {
                      int idx = v.toInt() - 1;
                      if (idx >= 0 && idx < 30) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            last30Days[idx].day.toString(),
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        );
                      }
                      return pw.SizedBox();
                    },
                  ),
                  yAxis: pw.FixedAxis(
                    [1, 2, 3, 4, 5],
                    ticks: true,
                    buildLabel: (v) {
                      int score = v.toInt();
                      if (moodImages.containsKey(score)) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 5),
                          child: pw.Image(moodImages[score]!, width: 14, height: 14),
                        );
                      }
                      return pw.SizedBox();
                    }
                  ),
                ),
                datasets: [
                  ...List.generate(5, (index) {
                    double yPos = (index + 1).toDouble();
                    return pw.LineDataSet(
                      color: const PdfColor.fromInt(0xFFEBEBEB), 
                      lineWidth: 1.5, 
                      drawPoints: false,
                      data: [
                        pw.PointChartValue(0, yPos), 
                        pw.PointChartValue(31, yPos),
                      ],
                    );
                  }),
                  pw.LineDataSet(
                    color: const PdfColor.fromInt(0xFFA5C9D5),
                    data: chartPoints.isEmpty ? [const pw.PointChartValue(1, 0)] : chartPoints,
                    lineWidth: 2,
                  ),
                  pw.PointDataSet(
                    color: const PdfColor.fromInt(0xFFF7C8D8),
                    data: chartPoints.isEmpty ? [const pw.PointChartValue(1, 0)] : chartPoints,
                  )
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("III. Most Emotion", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text("Period: $periodStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: top5.isEmpty
                    ? [pw.Text("No data available yet.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))]
                    : List.generate(top5.length, (i) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 15,
                                alignment: pw.Alignment.centerLeft,
                                child: emotionImages.containsKey(top5[i].key)
                                    ? pw.Image(emotionImages[top5[i].key]!, width: 12, height: 12)
                                    : pw.SizedBox(),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Container(
                                width: 55,
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Text(top5[i].key, style: const pw.TextStyle(fontSize: 10))
                              ),
                              pw.Container(
                                height: 10,
                                width: (top5[i].value / maxEmoCount) * 220,
                                color: barColors[i % barColors.length],
                              ),
                              pw.SizedBox(width: 5),
                              pw.Text("${top5[i].value} times", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            ],
                          ),
                        );
                      }),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("IV. Detail Mood", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            moodDocs.isEmpty
            ? pw.Text("No data available yet.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            : pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FixedColumnWidth(40),
                3: const pw.FixedColumnWidth(55),
                4: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("No.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Time", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Mood", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Emotion", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Journal", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                  ],
                ),
                ...moodDocs.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value.data() as Map<String, dynamic>;
                  DateTime d = DateTime.parse(item['date']);
                  String dateStr = DateFormat('dd MMM yyyy').format(d);
                  String timeStr = DateFormat('HH:mm').format(d);
                  
                  int moodScore = 5 - (item['mood'] as int);
                  String emotionStr = item['emotion'] ?? 'Unknown';

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("${index + 1}", style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("$dateStr\n$timeStr", style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Image(moodImages[moodScore]!, width: 18, height: 18))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (emotionImages.containsKey(emotionStr))
                                pw.Image(emotionImages[emotionStr]!, width: 14, height: 14),
                              pw.SizedBox(height: 2),
                              pw.Text(emotionStr, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)
                            ]
                          )
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['journal'] ?? '-', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 2, 
        shadowColor: Colors.black.withOpacity(0.3),
        scrolledUnderElevation: 2,
        titleSpacing: 12,
        leadingWidth: 72, 
        leading: Padding(
          padding: const EdgeInsets.only(left: 28.0, top: 8.0, bottom: 8.0), 
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7C8D8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            ),
          ),
        ),

        title: const Text(
          'Share Report',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () async {
                if (isLoading) return;
                final bytes = await _generatePdf(PdfPageFormat.a4);
                await Printing.sharePdf(bytes: bytes, filename: 'Mood_Report_${userData['name'] ?? 'User'}.pdf');
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFA5C9D5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ios_share, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => _generatePdf(format),
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              initialPageFormat: PdfPageFormat.a4,
              scrollViewDecoration: const BoxDecoration(color: Colors.white),
              pdfPreviewPageDecoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 2.0)),
              ),
              padding: EdgeInsets.zero,
            ),
    );
  }
}