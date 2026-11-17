
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../customer/order_detail_page.dart';

class JastiperOrdersPage extends StatefulWidget {
  final String uid;

  const JastiperOrdersPage({
    super.key,
    required this.uid,
  });

  @override
  State<JastiperOrdersPage> createState() =>
      _JastiperOrdersPageState();
}

class _JastiperOrdersPageState extends State<JastiperOrdersPage> {
  final OrderService _service = OrderService();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  final Set<String> _processingOrders = {};

  @override
  void initState() {
    super.initState();
    _stream = _service.getJastiperOrders(widget.uid);
  }

  String _rupiah(dynamic value) {
    final number = (value as num?)?.toInt() ?? 0;
    final text = number.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp$buffer';
  }

  String _tanggal(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu Konfirmasi';
      case 'diterima':
        return 'Pesanan Diterima';
      case 'diproses':
        return 'Sedang Diproses';
      case 'dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'ditolak':
      case 'dibatalkan':
        return AppColors.error;
      case 'dalam_perjalanan':
        return Colors.blue;
      case 'diterima':
      case 'diproses':
        return AppColors.primary;
      default:
        return Colors.orange;
    }
  }

  void _bukaDetail(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          order: order,
          currentUid: widget.uid,
          isJastiper: true,
        ),
      ),
    );
  }

  Future<void> _ubahStatus({
    required String orderId,
    required String status,
    required String pesan,
    String catatan = '',
  }) async {
    if (_processingOrders.contains(orderId)) return;

    setState(() {
      _processingOrders.add(orderId);
    });

    try {
      await _service.updateOrderStatus(
        orderId: orderId,
        statusBaru: status,
        alasanPenolakan: catatan,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pesanan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(orderId);
        });
      }
    }
  }

  Future<void> _konfirmasiTolak(String orderId) async {
    final controller = TextEditingController();

    final alasan = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tolak Permintaan Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berikan alasan yang jelas agar Customer '
                  'mengetahui mengapa pesanannya tidak dapat diproses.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kuota titipan sudah penuh...',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) return;

                Navigator.pop(dialogContext, text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (alasan == null || alasan.trim().isEmpty) return;

    await _ubahStatus(
      orderId: orderId,
      status: 'ditolak',
      catatan: alasan,
      pesan: 'Pesanan berhasil ditolak. Kuota dikembalikan.',
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 65,
              color: AppColors.primary,
            ),
            const SizedBox(height: 15),
            const Text(
              'Belum Ada Pesanan Masuk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan dari Customer akan muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(String orderId, String status) {
    final loading = _processingOrders.contains(orderId);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (status == 'menunggu') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _konfirmasiTolak(orderId),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _ubahStatus(
                orderId: orderId,
                status: 'diterima',
                pesan: 'Pesanan berhasil diterima.',
                catatan: 'Pesanan telah diperiksa dan diterima Jastiper.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Terima Pesanan'),
            ),
          ),
        ],
      );
    }

    String? nextStatus;
    String? buttonLabel;
    String? successMessage;
    String? progressNote;

    switch (status) {
      case 'diterima':
        nextStatus = 'diproses';
        buttonLabel = 'Mulai Proses Pesanan';
        successMessage = 'Pesanan sedang diproses.';
        progressNote = 'Jastiper mulai memproses pesanan.';
        break;

      case 'diproses':
        nextStatus = 'dalam_perjalanan';
        buttonLabel = 'Kirim Pesanan';
        successMessage = 'Pesanan sedang dalam perjalanan.';
        progressNote =
            'Pesanan telah dikirim dan sedang dalam perjalanan.';
        break;

      case 'dalam_perjalanan':
        nextStatus = 'selesai';
        buttonLabel = 'Selesaikan Pesanan';
        successMessage = 'Pesanan berhasil diselesaikan.';
        progressNote = 'Pesanan telah diselesaikan oleh Jastiper.';
        break;
    }

    if (nextStatus == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _ubahStatus(
          orderId: orderId,
          status: nextStatus!,
          pesan: successMessage!,
          catatan: progressNote!,
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(buttonLabel!),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'menunggu';
    final orderId = order['orderId'] as String? ?? '';

    final jumlah = (order['jumlah'] as num?)?.toInt() ?? 0;
    final total = (order['totalBiayaJasa'] as num?)?.toInt() ?? 0;

    final catatan = order['catatan']?.toString() ?? '';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['judulTitipan'] as String? ??
                      'Penawaran Titipan',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order['namaCustomer'] as String? ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order['kotaAsal'] ?? '-'} → ${order['kotaTujuan'] ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tanggal pesanan: ${_tanggal(order['createdAt'])}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jumlah pesanan',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                '$jumlah item',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total biaya jasa',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                _rupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Customer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    catatan,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (orderId.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _bukaDetail(order),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Lihat Detail & Chat Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (orderId.isNotEmpty &&
              status != 'selesai' &&
              status != 'ditolak' &&
              status != 'dibatalkan') ...[
            const SizedBox(height: 9),
            _actionButtons(orderId, status),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Pesanan Masuk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat pesanan: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data?.docs.map((doc) {
                final data = doc.data();
                return {
                  ...data,
                  'orderId': data['orderId'] ?? doc.id,
                };
              }).toList() ??
              [];

          if (orders.isEmpty) return _empty();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                '${orders.length} Pesanan Masuk',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...orders.map(_orderCard),
            ],
          );
        },
      ),
    );
  }
}
