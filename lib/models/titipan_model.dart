
import 'package:cloud_firestore/cloud_firestore.dart';

class TitipanModel {
  final String id;
  final String uid;
  final String namaJastiper;
  final String judul;
  final String deskripsi;
  final String kotaAsal;
  final String kotaTujuan;
  final String kategori;
  final DateTime tanggalBerangkat;
  final DateTime tanggalPulang;
  final int kuota;
  final int kuotaTerisi;
  final int biayaJasa;
  final String fotoUrl;
  final String status;
  final DateTime? createdAt;

  const TitipanModel({
    this.id = '',
    required this.uid,
    required this.namaJastiper,
    required this.judul,
    required this.deskripsi,
    required this.kotaAsal,
    required this.kotaTujuan,
    required this.kategori,
    required this.tanggalBerangkat,
    required this.tanggalPulang,
    required this.kuota,
    this.kuotaTerisi = 0,
    required this.biayaJasa,
    this.fotoUrl = '',
    this.status = 'aktif',
    this.createdAt,
  });

  bool get tersedia => status == 'aktif' && kuotaTerisi < kuota;

  int get sisaKuota => kuota - kuotaTerisi;

  factory TitipanModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return TitipanModel(
      id: documentId,
      uid: data['uid'] as String? ?? '',
      namaJastiper: data['namaJastiper'] as String? ?? '',
      judul: data['judul'] as String? ?? '',
      deskripsi: data['deskripsi'] as String? ?? '',
      kotaAsal: data['kotaAsal'] as String? ?? '',
      kotaTujuan: data['kotaTujuan'] as String? ?? '',
      kategori: data['kategori'] as String? ?? 'Lainnya',
      tanggalBerangkat: readDate(data['tanggalBerangkat']),
      tanggalPulang: readDate(data['tanggalPulang']),
      kuota: (data['kuota'] as num?)?.toInt() ?? 0,
      kuotaTerisi: (data['kuotaTerisi'] as num?)?.toInt() ?? 0,
      biayaJasa: (data['biayaJasa'] as num?)?.toInt() ?? 0,
      fotoUrl: data['fotoUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'aktif',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'namaJastiper': namaJastiper,
      'judul': judul,
      'deskripsi': deskripsi,
      'kotaAsal': kotaAsal,
      'kotaTujuan': kotaTujuan,
      'kategori': kategori,
      'tanggalBerangkat': Timestamp.fromDate(tanggalBerangkat),
      'tanggalPulang': Timestamp.fromDate(tanggalPulang),
      'kuota': kuota,
      'kuotaTerisi': kuotaTerisi,
      'biayaJasa': biayaJasa,
      'fotoUrl': fotoUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
