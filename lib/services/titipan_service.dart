
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/titipan_model.dart';

class TitipanService {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('titipan');

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Mengambil semua penawaran untuk marketplace Customer.
  Stream<List<TitipanModel>> getAllTitipan() {
    return _ref.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => TitipanModel.fromMap(doc.data(), doc.id))
          .where((item) => item.status == 'aktif')
          .toList();

      items.sort((a, b) => b.tanggalBerangkat.compareTo(a.tanggalBerangkat));
      return items;
    });
  }

  // Mengambil penawaran milik Jastiper yang sedang login.
  Stream<List<TitipanModel>> getMyTitipan(String uid) {
    return _ref.where('uid', isEqualTo: uid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => TitipanModel.fromMap(doc.data(), doc.id))
          .toList();

      items.sort((a, b) {
        final dateA = a.createdAt ?? a.tanggalBerangkat;
        final dateB = b.createdAt ?? b.tanggalBerangkat;
        return dateB.compareTo(dateA);
      });

      return items;
    });
  }

  // Upload foto penawaran ke Firebase Storage.
  Future<String> uploadFoto({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child(
      'titipan/$uid/$fileName',
    );

    final snapshot = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await snapshot.ref.getDownloadURL();
  }

  // Membuat penawaran baru.
  Future<void> createTitipan(
    TitipanModel titipan, {
    File? foto,
  }) async {
    String fotoUrl = '';

    if (foto != null) {
      fotoUrl = await uploadFoto(
        uid: titipan.uid,
        file: foto,
      );
    }

    final data = titipan.toMap();
    data['fotoUrl'] = fotoUrl;

    await _ref.add(data);
  }

  // Memperbarui penawaran.
  Future<void> updateTitipan(
    String id,
    String uid,
    Map<String, dynamic> data, {
    File? fotoBaru,
    String? fotoLama,
  }) async {
    final doc = await _ref.doc(id).get();

    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw Exception('Kamu tidak memiliki akses ke penawaran ini.');
    }

    if (fotoBaru != null) {
      final fotoUrl = await uploadFoto(
        uid: uid,
        file: fotoBaru,
      );

      data['fotoUrl'] = fotoUrl;

      if (fotoLama != null && fotoLama.isNotEmpty) {
        try {
          await _storage.refFromURL(fotoLama).delete();
        } catch (_) {
          // Penghapusan foto lama tidak boleh menggagalkan update.
        }
      }
    }

    await _ref.doc(id).update(data);
  }

  // Menghapus penawaran milik Jastiper.
  Future<void> deleteTitipan({
    required String id,
    required String uid,
    String? fotoUrl,
  }) async {
    final doc = await _ref.doc(id).get();

    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw Exception('Kamu tidak memiliki akses ke penawaran ini.');
    }

    await _ref.doc(id).delete();

    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(fotoUrl).delete();
      } catch (_) {
        // Data penawaran tetap terhapus jika foto sudah tidak tersedia.
      }
    }
  }

  // Mengubah status penawaran.
  Future<void> updateStatus({
    required String id,
    required String uid,
    required String status,
  }) async {
    if (!['aktif', 'nonaktif', 'selesai'].contains(status)) {
      throw Exception('Status penawaran tidak valid.');
    }

    final doc = await _ref.doc(id).get();

    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw Exception('Kamu tidak memiliki akses ke penawaran ini.');
    }

    await _ref.doc(id).update({'status': status});
  }
}
