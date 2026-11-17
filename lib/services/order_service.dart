
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('pesanan');

  CollectionReference<Map<String, dynamic>> get _titipan =>
      _db.collection('titipan');

  // =========================================================
  // MEMBUAT PESANAN
  // =========================================================

  Future<String> createOrder({
    required String titipanId,
    required String customerUid,
    required String namaCustomer,
    required String jastiperUid,
    required String namaJastiper,
    required String judulTitipan,
    required String fotoUrl,
    required String kotaAsal,
    required String kotaTujuan,
    required String kategori,
    required DateTime tanggalBerangkat,
    required DateTime tanggalTiba,
    required int biayaJasa,
    required int jumlah,
    required String catatan,
  }) async {
    if (jumlah < 1) {
      throw Exception('Jumlah pesanan minimal 1.');
    }

    if (biayaJasa < 0) {
      throw Exception('Biaya jasa tidak valid.');
    }

    final orderRef = _orders.doc();
    final titipanRef = _titipan.doc(titipanId);

    final totalBiayaJasa = biayaJasa * jumlah;

    await _db.runTransaction((transaction) async {
      final titipanSnapshot = await transaction.get(titipanRef);

      if (!titipanSnapshot.exists) {
        throw Exception('Titipan tidak ditemukan.');
      }

      final titipanData = titipanSnapshot.data()!;

      if (titipanData['uid'] != jastiperUid) {
        throw Exception('Mitra Jastip tidak sesuai.');
      }

      if (titipanData['status'] != 'aktif') {
        throw Exception('Titipan sudah tidak aktif.');
      }

      final kuota = (titipanData['kuota'] as num?)?.toInt() ?? 0;
      final kuotaTerisi =
          (titipanData['kuotaTerisi'] as num?)?.toInt() ?? 0;

      if (kuotaTerisi + jumlah > kuota) {
        throw Exception('Kuota titipan tidak mencukupi.');
      }

      transaction.update(titipanRef, {
        'kuotaTerisi': kuotaTerisi + jumlah,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(orderRef, {
        'orderId': orderRef.id,
        'titipanId': titipanId,

        'customerUid': customerUid,
        'namaCustomer': namaCustomer,

        'jastiperUid': jastiperUid,
        'namaJastiper': namaJastiper,

        'judulTitipan': judulTitipan,
        'fotoUrl': fotoUrl,

        'kotaAsal': kotaAsal,
        'kotaTujuan': kotaTujuan,
        'kategori': kategori,

        'tanggalBerangkat': Timestamp.fromDate(tanggalBerangkat),
        'tanggalTiba': Timestamp.fromDate(tanggalTiba),

        'biayaJasa': biayaJasa,
        'jumlah': jumlah,
        'totalBiayaJasa': totalBiayaJasa,

        'catatan': catatan,

        // STATUS PESANAN
        'status': 'menunggu',
        'alasanPenolakan': '',

        // INFORMASI PEMBAYARAN
        'paymentMethod': 'Transfer Bank',
        'paymentStatus': 'menunggu_pembayaran',
        'paymentBank': 'SeaBank',
        'paymentAccountNumber': '2312115799',
        'paymentAccountName': 'M Fazli Anan',
        'paymentAmount': totalBiayaJasa,
        'paymentConfirmation': null,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        'riwayatStatus': [
          {
            'status': 'menunggu',
            'waktu': Timestamp.now(),
            'keterangan': 'Pesanan berhasil dibuat.',
          }
        ],
      });
    });

    return orderRef.id;
  }

  // =========================================================
  // PESANAN CUSTOMER
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getCustomerOrders(
    String uid,
  ) {
    return _orders
        .where('customerUid', isEqualTo: uid)
        .snapshots();
  }

  // =========================================================
  // PESANAN JASTIPER
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getJastiperOrders(
    String uid,
  ) {
    return _orders
        .where('jastiperUid', isEqualTo: uid)
        .snapshots();
  }

  // =========================================================
  // KONFIRMASI PEMBAYARAN CUSTOMER
  // =========================================================

  Future<void> submitPaymentConfirmation({
    required String orderId,
    required String customerUid,
    required String namaPengirim,
    required String tanggalTransfer,
    required int nominalTransfer,
    required String nomorReferensi,
  }) async {
    if (namaPengirim.trim().isEmpty ||
        tanggalTransfer.trim().isEmpty ||
        nomorReferensi.trim().isEmpty) {
      throw Exception('Semua informasi pembayaran wajib diisi.');
    }

    if (nominalTransfer < 1) {
      throw Exception('Nominal transfer tidak valid.');
    }

    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Pesanan tidak ditemukan.');
      }

      final order = snapshot.data()!;

      if (order['customerUid'] != customerUid) {
        throw Exception('Kamu tidak memiliki akses ke pesanan ini.');
      }

      if (order['status'] == 'dibatalkan' ||
          order['status'] == 'ditolak') {
        throw Exception('Pesanan ini tidak dapat dibayar.');
      }

      if (order['paymentStatus'] != 'menunggu_pembayaran') {
        throw Exception(
          'Konfirmasi pembayaran sudah dikirim atau sedang diproses.',
        );
      }

      final tagihan =
          (order['paymentAmount'] as num?)?.toInt() ??
          (order['totalBiayaJasa'] as num?)?.toInt() ??
          0;

      if (nominalTransfer != tagihan) {
        throw Exception(
          'Nominal transfer harus sesuai tagihan Rp$tagihan.',
        );
      }

      transaction.update(orderRef, {
        'paymentStatus': 'menunggu_verifikasi_admin',
        'paymentConfirmation': {
          'namaPengirim': namaPengirim.trim(),
          'tanggalTransfer': tanggalTransfer.trim(),
          'nominalTransfer': nominalTransfer,
          'nomorReferensi': nomorReferensi.trim(),
          'submittedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================
  // UPDATE STATUS PESANAN OLEH JASTIPER
  // =========================================================

  Future<void> updateOrderStatus({
    required String orderId,
    required String statusBaru,
    String alasanPenolakan = '',
  }) async {
    const allowedStatuses = [
      'diterima',
      'diproses',
      'dalam_perjalanan',
      'selesai',
      'ditolak',
    ];

    if (!allowedStatuses.contains(statusBaru)) {
      throw Exception('Status pesanan tidak valid.');
    }

    if (statusBaru == 'ditolak' &&
        alasanPenolakan.trim().isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }

    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Pesanan tidak ditemukan.');
      }

      final order = snapshot.data()!;

      final statusLama = order['status'] as String? ?? 'menunggu';

      final paymentStatus =
          order['paymentStatus'] as String? ?? 'menunggu_pembayaran';

      // =====================================================
      // PEMERIKSAAN PEMBAYARAN
      // =====================================================

      // Jastiper dapat menerima pesanan setelah Customer
      // mengirim konfirmasi pembayaran.
      //
      // Status pembayaran tidak diubah menjadi berhasil.
      // Jastiper bukan pihak yang memverifikasi mutasi bank.

      if (statusLama == 'menunggu' &&
          statusBaru == 'diterima' &&
          paymentStatus != 'menunggu_verifikasi_admin' &&
          paymentStatus != 'berhasil') {
        throw Exception(
          'Customer harus mengirim konfirmasi pembayaran terlebih dahulu.',
        );
      }

      // =====================================================
      // TRANSISI STATUS
      // =====================================================

      final Map<String, List<String>> transitions = {
        'menunggu': ['diterima', 'ditolak'],
        'diterima': ['diproses'],
        'diproses': ['dalam_perjalanan'],
        'dalam_perjalanan': ['selesai'],
      };

      final allowedNext = transitions[statusLama] ?? [];

      if (!allowedNext.contains(statusBaru)) {
        throw Exception(
          'Perubahan status dari $statusLama ke $statusBaru tidak diperbolehkan.',
        );
      }

      // =====================================================
      // UPDATE PESANAN
      // =====================================================

      transaction.update(orderRef, {
        'status': statusBaru,
        'alasanPenolakan':
            statusBaru == 'ditolak' ? alasanPenolakan.trim() : '',
        'updatedAt': FieldValue.serverTimestamp(),
        'riwayatStatus': FieldValue.arrayUnion([
          {
            'status': statusBaru,
            'waktu': Timestamp.now(),
            'keterangan': statusBaru == 'ditolak'
                ? alasanPenolakan.trim()
                : 'Status pesanan diperbarui.',
          }
        ]),
      });

      // =====================================================
      // KEMBALIKAN KUOTA JIKA PESANAN DITOLAK
      // =====================================================

      if (statusBaru == 'ditolak') {
        final titipanId = order['titipanId'] as String? ?? '';
        final jumlah = (order['jumlah'] as num?)?.toInt() ?? 1;

        if (titipanId.isNotEmpty) {
          final titipanRef = _titipan.doc(titipanId);
          final titipanSnapshot = await transaction.get(titipanRef);

          if (titipanSnapshot.exists) {
            final titipanData = titipanSnapshot.data()!;

            final kuotaTerisi =
                (titipanData['kuotaTerisi'] as num?)?.toInt() ?? 0;

            transaction.update(titipanRef, {
              'kuotaTerisi': (kuotaTerisi - jumlah).clamp(0, 999999),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  // =========================================================
  // PEMBATALAN PESANAN CUSTOMER
  // =========================================================

  Future<void> cancelCustomerOrder({
    required String orderId,
    required String customerUid,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Pesanan tidak ditemukan.');
      }

      final order = snapshot.data()!;

      if (order['customerUid'] != customerUid) {
        throw Exception('Kamu tidak memiliki akses ke pesanan ini.');
      }

      if (order['status'] != 'menunggu') {
        throw Exception(
          'Pesanan tidak dapat dibatalkan karena sudah diproses.',
        );
      }

      if (order['paymentStatus'] != 'menunggu_pembayaran') {
        throw Exception(
          'Pesanan tidak dapat dibatalkan setelah konfirmasi pembayaran dikirim.',
        );
      }

      final titipanId = order['titipanId'] as String? ?? '';
      final jumlah = (order['jumlah'] as num?)?.toInt() ?? 1;

      transaction.update(orderRef, {
        'status': 'dibatalkan',
        'paymentStatus': 'dibatalkan',
        'updatedAt': FieldValue.serverTimestamp(),
        'riwayatStatus': FieldValue.arrayUnion([
          {
            'status': 'dibatalkan',
            'waktu': Timestamp.now(),
            'keterangan': 'Pesanan dibatalkan oleh customer.',
          }
        ]),
      });

      if (titipanId.isNotEmpty) {
        final titipanRef = _titipan.doc(titipanId);
        final titipanSnapshot = await transaction.get(titipanRef);

        if (titipanSnapshot.exists) {
          final titipanData = titipanSnapshot.data()!;

          final kuotaTerisi =
              (titipanData['kuotaTerisi'] as num?)?.toInt() ?? 0;

          transaction.update(titipanRef, {
            'kuotaTerisi': (kuotaTerisi - jumlah).clamp(0, 999999),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
}
