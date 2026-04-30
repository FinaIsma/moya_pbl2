class Mood {
  final String time;
  final List<String> emotions;
  final String note;
  final DateTime date;
  final int moodIndex;
  final String? photoUrl;

  Mood({
    required this.time,
    required this.emotions,
    required this.note,
    required this.date,
    required this.moodIndex, 
    this.photoUrl,
  });

  factory Mood.fromFirestore(Map<String, dynamic> data) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(data['date']);
    } catch (e) {
      parsedDate = DateTime.now();
    }

  
    print("DATA FIREBASE: $data");
    print("MOOD INDEX: ${data['mood']}");

    String formattedTime =
    "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
    return Mood(
      moodIndex: data['mood'] ?? 0,       
      emotions: List<String>.from(data['emotion'] ?? []),
      note: data['journal'] ?? '',
      date: parsedDate,
      time: formattedTime,
      photoUrl: data['photoUrl'],
    );
  }
}