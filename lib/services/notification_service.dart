import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'chat_channel';
  static const _channelName = 'Chat Messages';

  static Future<void> init() async {
    // Android init settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap notifikasi → navigasi ke chat screen
        handleNotifTap(details.payload);
      },
    );

    // Buat notification channel (wajib Android 8+)
    await _createNotificationChannel();

    // Minta permission notif
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi pesan chat',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showChatNotification({
    required String senderName,
    required String message,
    String? payload, // bisa isi chatRoomId untuk navigasi
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      senderName,
      message,
      notifDetails,
      payload: payload,
    );
  }

  static void handleNotifTap(String? payload) {
    if (payload == null) return;
    // Navigasi ke chat room berdasarkan payload (chatRoomId)
    // Contoh: NavigationService.navigateTo('/chat', arguments: payload);
  }
}