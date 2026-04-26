import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisplayNameHelper {
  /// Kembalikan nama yang akan ditampilkan untuk sebuah post/reply
  /// - Kalau uid == user sendiri → nama asli dari Firestore
  /// - Kalau uid orang lain → "Anonymous" + 4 digit terakhir uid
  static Future<String> getDisplayName(String uid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid == currentUid) {
      // Post milik sendiri → tampil nama asli
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['name'] ?? 'You';
      }
      return 'You';
    } else {
      // Post orang lain → anonim dengan suffix uid biar konsisten
      final suffix = uid.length >= 4
          ? uid.substring(uid.length - 4).toUpperCase()
          : uid.toUpperCase();
      return 'Anonymous$suffix';
    }
  }

  /// Cek apakah uid adalah user yang sedang login
  static bool isCurrentUser(String uid) {
    return uid == (FirebaseAuth.instance.currentUser?.uid ?? '');
  }
}
