
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String nomorTelepon;
  final String fotoProfil;
  final String activeMode;
  final bool isJastiper;
  final DateTime? createdAt;

  // Informasi umum pengguna
  final String alamat;
  final String kotaDomisili;

  // Informasi khusus Jastiper
  final String username;
  final String namaLayanan;
  final String fotoSampul;
  final String deskripsiLayanan;
  final String nomorWhatsapp;
  final List<String> kategoriLayanan;
  final List<String> wilayahLayanan;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    this.nomorTelepon = '',
    this.fotoProfil = '',
    this.activeMode = 'customer',
    this.isJastiper = false,
    this.createdAt,
    this.alamat = '',
    this.kotaDomisili = '',
    this.username = '',
    this.namaLayanan = '',
    this.fotoSampul = '',
    this.deskripsiLayanan = '',
    this.nomorWhatsapp = '',
    this.kategoriLayanan = const [],
    this.wilayahLayanan = const [],
  });

  factory UserModel.fromMap(
    Map<String, dynamic> data,
    String uid,
  ) {
    return UserModel(
      uid: uid,
      nama: data['nama'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nomorTelepon: data['nomorTelepon'] as String? ?? '',
      fotoProfil: data['fotoProfil'] as String? ?? '',
      activeMode: data['activeMode'] as String? ?? 'customer',
      isJastiper: data['isJastiper'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),

      alamat: data['alamat'] as String? ?? '',
      kotaDomisili: data['kotaDomisili'] as String? ?? '',

      username: data['username'] as String? ?? '',
      namaLayanan: data['namaLayanan'] as String? ?? '',
      fotoSampul: data['fotoSampul'] as String? ?? '',
      deskripsiLayanan: data['deskripsiLayanan'] as String? ?? '',
      nomorWhatsapp: data['nomorWhatsapp'] as String? ?? '',
      kategoriLayanan: List<String>.from(
        data['kategoriLayanan'] ?? const [],
      ),
      wilayahLayanan: List<String>.from(
        data['wilayahLayanan'] ?? const [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nomorTelepon': nomorTelepon,
      'fotoProfil': fotoProfil,
      'activeMode': activeMode,
      'isJastiper': isJastiper,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),

      'alamat': alamat,
      'kotaDomisili': kotaDomisili,

      'username': username,
      'namaLayanan': namaLayanan,
      'fotoSampul': fotoSampul,
      'deskripsiLayanan': deskripsiLayanan,
      'nomorWhatsapp': nomorWhatsapp,
      'kategoriLayanan': kategoriLayanan,
      'wilayahLayanan': wilayahLayanan,
    };
  }

  UserModel copyWith({
    String? nama,
    String? email,
    String? nomorTelepon,
    String? fotoProfil,
    String? activeMode,
    bool? isJastiper,
    String? alamat,
    String? kotaDomisili,
    String? username,
    String? namaLayanan,
    String? fotoSampul,
    String? deskripsiLayanan,
    String? nomorWhatsapp,
    List<String>? kategoriLayanan,
    List<String>? wilayahLayanan,
  }) {
    return UserModel(
      uid: uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nomorTelepon: nomorTelepon ?? this.nomorTelepon,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      activeMode: activeMode ?? this.activeMode,
      isJastiper: isJastiper ?? this.isJastiper,
      createdAt: createdAt,
      alamat: alamat ?? this.alamat,
      kotaDomisili: kotaDomisili ?? this.kotaDomisili,
      username: username ?? this.username,
      namaLayanan: namaLayanan ?? this.namaLayanan,
      fotoSampul: fotoSampul ?? this.fotoSampul,
      deskripsiLayanan: deskripsiLayanan ?? this.deskripsiLayanan,
      nomorWhatsapp: nomorWhatsapp ?? this.nomorWhatsapp,
      kategoriLayanan: kategoriLayanan ?? this.kategoriLayanan,
      wilayahLayanan: wilayahLayanan ?? this.wilayahLayanan,
    );
  }
}
