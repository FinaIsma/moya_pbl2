class Psychologist {
  final String id;
  final String name;
  final String title;
  final int experience;
  final double rating;
  final int totalConsult;
  final List<String> expertise;
  final String? photoUrl;
  final String gender;
  final int age;
  final String about;
  final List<String> education;

  Psychologist({
    required this.id,
    required this.name,
    required this.title,
    required this.experience,
    required this.rating,
    required this.totalConsult,
    required this.expertise,
    this.photoUrl,
    required this.gender,
    required this.age,
    required this.about,
    required this.education,
  });

    factory Psychologist.fromFirestore(Map<String, dynamic> data, String id) {
    return Psychologist(
      id: id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      experience: int.tryParse(data['experience'].toString()) ?? 0,
      rating: double.tryParse(data['rating'].toString()) ?? 0.0,
      totalConsult: int.tryParse(data['totalConsult'].toString()) ?? 0,
      expertise: List<String>.from(data['expertise'] ?? []),
      photoUrl: data['photoUrl']?.toString(),
      gender: data['gender'] ?? '',
      age: int.tryParse(data['age'].toString()) ?? 0,
      about: data['about'] ?? '',
      education: List<String>.from(data['education'] ?? []),
    );
  }
}