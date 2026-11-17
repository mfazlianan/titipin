
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(
    String orderId,
  ) {
    return _db
        .collection('pesanan')
        .doc(orderId)
        .collection('messages');
  }

  // Mengambil pesan secara real-time.
  Stream<List<Map<String, dynamic>>> getMessages(
    String orderId,
  ) {
    return _messages(orderId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'messageId': doc.id,
        };
      }).toList();
    });
  }

  // Mengirim pesan.
  Future<void> sendMessage({
    required String orderId,
    required String senderUid,
    required String senderName,
    required String message,
  }) async {
    final text = message.trim();

    if (orderId.trim().isEmpty) {
      throw Exception('ID pesanan tidak valid.');
    }

    if (text.isEmpty) {
      throw Exception('Pesan tidak boleh kosong.');
    }

    if (text.length > 2000) {
      throw Exception('Pesan maksimal 2000 karakter.');
    }

    if (senderUid.trim().isEmpty) {
      throw Exception('Identitas pengirim tidak valid.');
    }

    await _messages(orderId).add({
      'senderUid': senderUid,
      'senderName': senderName.trim(),
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
