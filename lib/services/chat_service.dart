import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;

  // ─── Cloudinary config ────────────────────────────────────
  static const String _cloudName       = 'drkxaqn7z';
  static const Map<String, dynamic> _serviceAccount = {
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/hOO/Ho9PbONR\nQBasZKdHhCakGVLnPsDfz8Ah78WLBrdRul0qHqrYCxcNKDK9ywVF8EFKCChT0fXO\nOxiuuhI3r2SGF27HM5VV7gaWih6JIYDI6sow5QKd3JKC6BByJVvzdIgDhyJR49SV\n56D0hAjMe1017k4VpQH3wptP4KHZLyXrff1gsNkbQrIfE8WaDjnbA0MkCIdiHqJN\nnETcgvanoabkFCbU00+7+Fwn/zbX+3Num3JRs3iuzBW4x+4sPryEibXXDx3Dw/C8\n42hMfgGnoaltYIkxQkIm9rD6P3L+ahdTv2M1EzMSSnvUTEC6y90Ddu5M7v8r0tUo\nLfsXF7ifAgMBAAECggEAEEIcQV+7Q79XJtEde6IJz1jpHNonfwkFP5q30Um1B+HY\nkyASg55Z24BJgyzr7c+70V2ddUbvAXqb9tdud3rFTCPgEUAQ/+khnstXlNUB1ZtZ\n/vRrmK4ARF1ytJk1uDLytN6qIz6IC9Ke++DPeaJxysYYOhlSWKUK3zkOjT/hDXo8\n5AOpJ75EnFjNPXjP8VuuSdzK52mpBStvYMHVfxeF90quhJuZ+U+81PD2v5rq5yxo\nCEO8ShOzK9l85XRtfm8xBANanFYTjIFryrccZzUHLOvEK3HacL9XmCF1nh4EVE87\nhvXKSIm4+nMuKa8wV5AkGe9FyDJa6avdd61cXwUABQKBgQD0Mlbqw4oZsyLCP31T\ndFbIHJTA1Ct1ZmnPAAZrRtDJp9cwsPNqyEMA+rT9J7h+HnUNWT3NUgEER3ktrkoF\nfKzliELScma87OXY5iCtD9MrDQccSg58LbKkXUs32g31SjYLRGq2AAPlvgEc4SRt\n7dqZXDcaEGd+9UTMeYueLsfRWwKBgQDIxrl1hpuhZnMC+s17mGyeVGNiZESVEAAr\n5QIh9+92yp1agkRMvqbk3jcrKbRTuCdBQ6TNkaeVfEyLjhm9BlIojykE86lH5Vck\njjlIEmIqDZKn3M19POeaUKCCpaygov28H9XTxmsZgmKyT48T/bfggyJNDFK3rpfU\nG+chAKL1DQKBgQDfu6Nw0pkb9Ml66YqcxLGiBLWxenMazCtTUbWP4kD3EYUSgn1z\nL2pcYlcivprFSoh6I3KBRInT7twyo0YEgvcyEccPY2uH2xC3yhjUFvSls/j4zU06\nLvBGsYdx86HoRAcCCbwvZhIsEwqX+BtVcKBg9GEzyyXX50YShaYK1teSkwKBgGdo\nQrjPPXThaTcNqauQk9DwMcfJULFdblktN+363rDWJjkpgrfsMdUKxmtKrX+5By7M\nAiOGc0PAo0P1Sjha+xG8uim8vWE0M6+2OLZwEXMLTo96X7OzHK4T/LeNUN3jVMAB\nvYW3Wg3nY6Hm7BAlywCtSYtZX3kPSU+Ll30d8NA5AoGBANmzemEOY4RSDVNOS8vQ\nE1hyz13neA0Os86SnFpXSMGIMefbRmXI45RIx056C6SB+igi2QPnkVvllXmvEscH\nXsmdh1WmpH8xDahB50Q4fjfRfQxQQNQCpQWUaxWVz54BvUzrdUqiKyLQc2GPdwph\nF5+f3lznSn+9i+uc4yYsGS/d\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@moyaapp-pbl2.iam.gserviceaccount.com",
  "project_id": "moyaapp-pbl2",
};
  static const String _uploadPresetImg = 'mooya_preset';     // Khusus Gambar
  static const String _uploadPresetDoc = 'mooya_preset_doc'; // Khusus Dokumen (Yang baru dibuat)

  // ─── Get current user uid ─────────────────────────────────
  static String get currentUid => _auth.currentUser?.uid ?? '';

  // ─── Buat atau ambil room chat yang sudah ada ─────────────
  static Future<String> getOrCreateRoom({
    required String userUid,
    required String psikologUid,
  }) async {
    final existing = await _firestore
        .collection('chat_rooms')
        .where('user_uid', isEqualTo: userUid)
        .where('psikolog_uid', isEqualTo: psikologUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final roomRef = await _firestore.collection('chat_rooms').add({
      'user_uid':      userUid,
      'psikolog_uid':  psikologUid,
      'created_at':    FieldValue.serverTimestamp(),
      'last_message':  '',
      'last_message_at': FieldValue.serverTimestamp(),
    });

    return roomRef.id;
  }

  // ─── Stream messages realtime ─────────────────────────────
  static Stream<QuerySnapshot> streamMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  // ─── Stream semua chat rooms milik user ───────────────────
  static Stream<QuerySnapshot> streamUserRooms(String userUid) {
    return _firestore
        .collection('chat_rooms')
        .where('user_uid', isEqualTo: userUid)
        .orderBy('last_message_at', descending: true)
        .snapshots();
  }

  // ─── Stream semua chat rooms milik psikolog ───────────────
  static Stream<QuerySnapshot> streamPsikologRooms(String psikologUid) {
    return _firestore
        .collection('chat_rooms')
        .where('psikolog_uid', isEqualTo: psikologUid)
        .orderBy('last_message_at', descending: true)
        .snapshots();
  }

  // ─── Kirim pesan teks ─────────────────────────────────────
  static Future<void> sendText({
    required String roomId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'sender_uid': currentUid,
      'type':       'text',
      'content':    text.trim(),
      'is_read':    false,
      'created_at': FieldValue.serverTimestamp(),
    });

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'last_message':    text.trim(),
      'last_message_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _sendNotification(roomId: roomId);
  }

  // ─── Upload file/gambar ke Cloudinary ────────────────────
  static Future<String?> _uploadToCloudinary({
    required File file, 
    required String type, 
    required String preset,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$type/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = preset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body     = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);

        // Untuk raw file: ambil secure_url lalu sisipkan fl_attachment
        // supaya Cloudinary mengizinkan download langsung (bypass 401)
        String url = data['secure_url'] as String;
        if (type == 'raw') {
          url = url.replaceFirst('/upload/', '/upload/fl_attachment/');
        }
        return url;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Kirim gambar dari gallery ────────────────────────────
  static Future<void> sendImage({required String roomId}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    final file = File(picked.path);
    // Memakai preset gambar
    final url  = await _uploadToCloudinary(
      file: file, 
      type: 'image', 
      preset: _uploadPresetImg,
    );
    if (url == null) return;

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'sender_uid': currentUid,
      'type':       'image',
      'file_url':   url,
      'is_read':    false,
      'created_at': FieldValue.serverTimestamp(),
    });

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'last_message':    '📷 Photo',
      'last_message_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _sendNotification(roomId: roomId);
  }

  // ─── Kirim dokumen/file ───────────────────────────────────
  static Future<void> sendDocument({required String roomId}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;

    final file     = File(result.files.single.path!);
    final fileName = result.files.single.name;
    
    // Memakai preset dokumen khusus (raw)
    final url      = await _uploadToCloudinary(
      file: file, 
      type: 'raw', 
      preset: _uploadPresetDoc,
    );
    if (url == null) return;

    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'sender_uid':  currentUid,
      'type':        'document',
      'file_url':    url,
      'file_name':   fileName,
      'is_read':     false,
      'created_at':  FieldValue.serverTimestamp(),
    });

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'last_message':    '📄 $fileName',
      'last_message_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _sendNotification(roomId: roomId);
  }

  // ─── Mark messages as read ────────────────────────────────
  static Future<void> markAsRead(String roomId) async {
    final unread = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .where('is_read', isEqualTo: false)
        .where('sender_uid', isNotEqualTo: currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

static Future<String?> _getAccessToken() async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final jwt = JWT({
    'iss': _serviceAccount['client_email'],
    'scope': 'https://www.googleapis.com/auth/firebase.messaging',
    'aud': 'https://oauth2.googleapis.com/token',
    'iat': now,
    'exp': now + 3600,
  });

  final privateKey = _serviceAccount['private_key']!.replaceAll(r'\n', '\n');

  final token = jwt.sign(
    RSAPrivateKey(privateKey),
    algorithm: JWTAlgorithm.RS256,
  );

  final response = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': token,
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['access_token'] as String?;
  }
  return null;
}

static Future<void> _sendNotification({required String roomId}) async {
  final roomDoc = await _firestore.collection('chat_rooms').doc(roomId).get();
  if (!roomDoc.exists) return;

  final roomData    = roomDoc.data()!;
  final userUid     = roomData['user_uid'] as String? ?? '';
  final psikologUid = roomData['psikolog_uid'] as String? ?? '';

  String recipientToken = '';
  String senderName = 'New Messages';

  if (currentUid == userUid) {
    final q = await _firestore
        .collection('psychologists')
        .where('uid', isEqualTo: psikologUid)
        .limit(1).get();
    if (q.docs.isNotEmpty) {
      recipientToken = q.docs.first.data()['fcm_token'] ?? '';
    }
    final userDoc = await _firestore.collection('users').doc(currentUid).get();
    senderName = userDoc.data()?['name'] ?? senderName;
  } else {
    final userDoc = await _firestore.collection('users').doc(userUid).get();
    recipientToken = userDoc.data()?['fcm_token'] ?? '';
    final q = await _firestore
        .collection('psychologists')
        .where('uid', isEqualTo: currentUid)
        .limit(1).get();
    if (q.docs.isNotEmpty) {
      senderName = q.docs.first.data()['name'] ?? senderName;
    }
  }

if (recipientToken.isEmpty) return;

// Tambah ini
final recipientUid = currentUid == userUid ? psikologUid : userUid;
if (recipientUid == currentUid) return;

  final accessToken = await _getAccessToken();
  if (accessToken == null) return;

  await http.post(
    Uri.parse(
      'https://fcm.googleapis.com/v1/projects/${_serviceAccount['project_id']}/messages:send',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({
      'message': {
        'token': recipientToken,
        'data': {
          'senderName': senderName,
          'message': 'New message from $senderName',
          'chatRoomId': roomId,
        },
        'android': {'priority': 'high'},
      }
    }),
  );
}
}