import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:moya_pbl2/services/nav_key.dart';
import 'package:moya_pbl2/screens/chat_room_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  static Future<void> handleNotifTap(String? payload) async {
    if (payload == null) return;
    final roomId = payload;

    // Ambil data room
    final roomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(roomId)
        .get();

    if (!roomDoc.exists) return;

    final roomData = roomDoc.data()!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final psikologUid = roomData['psikolog_uid'] as String? ?? '';

    // Fetch data psikolog untuk header AppBar
    String psikologName = '';
    String psikologPhotoUrl = '';

    final psychQuery = await FirebaseFirestore.instance
        .collection('psychologists')
        .where('uid', isEqualTo: psikologUid)
        .limit(1)
        .get();

    if (psychQuery.docs.isNotEmpty) {
      final d = psychQuery.docs.first.data();
      psikologName = d['name'] ?? '';
      psikologPhotoUrl = d['photo_url'] ?? '';
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          roomId: roomId,
          psikologUid: psikologUid,
          psikologName: psikologName,
          psikologPhotoUrl: psikologPhotoUrl,
        ),
      ),
    );
  }
}