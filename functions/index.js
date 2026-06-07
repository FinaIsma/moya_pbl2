// functions/index.js
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.onNewChatMessage = onDocumentCreated(
  'chat_rooms/{chatRoomId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const chatRoomId = event.params.chatRoomId;
    const senderUid = message.sender_uid;
    if (!senderUid) return;

    // Ambil data room
    const roomDoc = await getFirestore()
      .collection('chat_rooms').doc(chatRoomId).get();
    if (!roomDoc.exists) return;

    const room = roomDoc.data();
    const userUid     = room.user_uid;
    const psikologUid = room.psikolog_uid;

    // Tentukan siapa penerima dan dari collection mana ambil tokennya
    let recipientUid;
    let recipientCollection;
    let senderCollection;

    if (senderUid === userUid) {
      // Pengirim = user biasa → kirim ke psikolog
      recipientUid        = psikologUid;
      recipientCollection = 'psychologists'; // query by uid field
      senderCollection    = 'users';         // query by doc id
    } else {
      // Pengirim = psikolog → kirim ke user
      recipientUid        = userUid;
      recipientCollection = 'users';         // query by doc id
      senderCollection    = 'psychologists'; // query by uid field
    }

    // Ambil nama pengirim
    let senderName = 'Pesan baru';
    if (senderCollection === 'users') {
      const senderDoc = await getFirestore()
        .collection('users').doc(senderUid).get();
      if (senderDoc.exists) senderName = senderDoc.data()?.name ?? senderName;
    } else {
      const senderQuery = await getFirestore()
        .collection('psychologists')
        .where('uid', '==', senderUid).limit(1).get();
      if (!senderQuery.empty) senderName = senderQuery.docs[0].data()?.name ?? senderName;
    }

    // Ambil FCM token penerima
    let recipientToken = null;
    if (recipientCollection === 'users') {
      const recipientDoc = await getFirestore()
        .collection('users').doc(recipientUid).get();
      recipientToken = recipientDoc.data()?.fcm_token ?? null;
    } else {
      const recipientQuery = await getFirestore()
        .collection('psychologists')
        .where('uid', '==', recipientUid).limit(1).get();
      if (!recipientQuery.empty) {
        recipientToken = recipientQuery.docs[0].data()?.fcm_token ?? null;
      }
    }

    if (!recipientToken) return; // user belum punya token, skip

    // Kirim notifikasi
    const messageText = message.type === 'text'
      ? (message.content ?? '')
      : message.type === 'image' ? '📷 Photo'
      : `📄 ${message.file_name ?? 'Document'}`;

    await getMessaging().send({
      token: recipientToken,
      data: {
        senderName,
        message:    messageText,
        chatRoomId,
      },
      android: { priority: 'high' },
    });
  }
);