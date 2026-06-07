import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'package:moya_pbl2/services/nav_key.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // tambah ini

// Handler background (harus top-level function, di luar class!)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showChatNotification(
    senderName: message.data['senderName'] ?? 'Pesan baru',
    message: message.data['message'] ?? '',
    payload: message.data['chatRoomId'],
  );
}

class FCMService {
  static Future<void> init() async {
    // Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    // Tambah di dalam FCMService.init(), setelah onBackgroundMessage
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update token di collection yang tepat
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .set({'fcm_token': newToken}, SetOptions(merge: true));
        return;
      }

      final psychQuery = await FirebaseFirestore.instance
          .collection('psychologists')
          .where('uid', isEqualTo: user.uid)
          .limit(1).get();

      if (psychQuery.docs.isNotEmpty) {
        await psychQuery.docs.first.reference
            .set({'fcm_token': newToken}, SetOptions(merge: true));
      }
    });

    // Foreground: saat app terbuka
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.showChatNotification(
        senderName: message.data['senderName'] ?? 'Pesan baru',
        message: message.data['message'] ?? '',
        payload: message.data['chatRoomId'],
      );
    });

    // App dibuka dari notif (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        NotificationService.handleNotifTap(message.data['chatRoomId']);
      }
    });

    // App di background lalu tap notif
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationService.handleNotifTap(message.data['chatRoomId']);
    });
  }
}