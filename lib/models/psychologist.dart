class Psychologist {
  final String id;
  final String name;
  final String title;
  final int experience;
  final int price;
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
    required this.price,
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
      experience: data['experience'] ?? 0,
      price: data['price'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      totalConsult: data['totalConsult'] ?? 0,
      expertise: List<String>.from(data['expertise'] ?? []),
      photoUrl: data['photoUrl'] as String?,
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      about: data['about'] ?? '',
      education: List<String>.from(data['education'] ?? []),
    );
  }
}