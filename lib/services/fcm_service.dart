import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

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