
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUser(UserModel user) async {
    await _ref.doc(user.uid).set(user.toMap());
  }

  Future<void> ensureUserDocument({
    required String uid,
    required String nama,
    required String email,
  }) async {
    final doc = await _ref.doc(uid).get();

    if (!doc.exists) {
      final user = UserModel(
        uid: uid,
        nama: nama,
        email: email,
      );

      await createUser(user);
    }
  }

  Stream<UserModel?> userStream(String uid) {
    return _ref.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _ref.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateActiveMode(
    String uid,
    String mode,
  ) async {
    if (mode != 'customer' && mode != 'jastiper') {
      throw Exception('Mode tidak valid');
    }

    await _ref.doc(uid).update({
      'activeMode': mode,
      if (mode == 'jastiper') 'isJastiper': true,
    });
  }

  // Memperbarui profil umum Customer maupun Jastiper.
  Future<void> updateProfile({
    required String uid,
    required String nama,
    required String nomorTelepon,
    String? fotoProfil,
    String? alamat,
    String? kotaDomisili,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'nama': nama.trim(),
      'nomorTelepon': nomorTelepon.trim(),
    };

    if (fotoProfil != null) {
      data['fotoProfil'] = fotoProfil;
    }

    if (alamat != null) {
      data['alamat'] = alamat.trim();
    }

    if (kotaDomisili != null) {
      data['kotaDomisili'] = kotaDomisili.trim();
    }

    if (email != null) {
      data['email'] = email.trim();
    }

    await _ref.doc(uid).update(data);
  }

  // Memperbarui informasi khusus Jastiper.
  Future<void> updateJastiperProfile({
    required String uid,
    required String username,
    required String namaLayanan,
    required String deskripsiLayanan,
    required String nomorWhatsapp,
    required List<String> kategoriLayanan,
    required List<String> wilayahLayanan,
    String? fotoSampul,
  }) async {
    final data = <String, dynamic>{
      'username': username.trim(),
      'namaLayanan': namaLayanan.trim(),
      'deskripsiLayanan': deskripsiLayanan.trim(),
      'nomorWhatsapp': nomorWhatsapp.trim(),
      'kategoriLayanan': kategoriLayanan,
      'wilayahLayanan': wilayahLayanan,
      'isJastiper': true,
    };

    if (fotoSampul != null) {
      data['fotoSampul'] = fotoSampul;
    }

    await _ref.doc(uid).update(data);
  }
}
