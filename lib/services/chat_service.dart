import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;

  // ─── Cloudinary config ────────────────────────────────────
  // Ganti dengan nilai asli dari temenmu
  static const String _cloudName    = 'drkxaqn7z';
  static const String _uploadPreset = 'mooya_preset';

  // ─── Get current user uid ─────────────────────────────────
  static String get currentUid => _auth.currentUser?.uid ?? '';

  // ─── Buat atau ambil room chat yang sudah ada ─────────────
  // Kalau room antara userUid dan psikologUid sudah ada → return roomId lama
  // Kalau belum ada → buat baru
  static Future<String> getOrCreateRoom({
    required String userUid,
    required String psikologUid,
  }) async {
    // Cek apakah room sudah ada
    final existing = await _firestore
        .collection('chat_rooms')
        .where('user_uid', isEqualTo: userUid)
        .where('psikolog_uid', isEqualTo: psikologUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Buat room baru
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

    // Tambah pesan ke subcollection
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

    // Update last message di room
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'last_message':    text.trim(),
      'last_message_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ─── Upload file/gambar ke Cloudinary ────────────────────
  static Future<String?> _uploadToCloudinary(File file, String type) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$type/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['secure_url'] as String;
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
    final url  = await _uploadToCloudinary(file, 'image');
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
    final url      = await _uploadToCloudinary(file, 'raw');
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
}
