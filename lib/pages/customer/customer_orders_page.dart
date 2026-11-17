
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'order_detail_page.dart';
import 'payment_confirmation_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  final String uid;

  const CustomerOrdersPage({
    super.key,
    required this.uid,
  });

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final OrderService _service = OrderService();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _service.getCustomerOrders(widget.uid);
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

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_verifikasi_admin':
        return 'Menunggu Verifikasi Admin';
      case 'berhasil':
        return 'Pembayaran Berhasil';
      case 'ditolak':
        return 'Pembayaran Ditolak';
      case 'dibatalkan':
        return 'Pembayaran Dibatalkan';
      default:
        return 'Status Belum Diketahui';
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'berhasil':
        return Colors.green;
      case 'menunggu_verifikasi_admin':
        return Colors.blue;
      case 'ditolak':
      case 'dibatalkan':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  Future<void> _batalkan(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Pesanan yang masih menunggu pembayaran akan dibatalkan. '
          'Kuota titipan akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelCustomerOrder(
        orderId: orderId,
        customerUid: widget.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membatalkan pesanan: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _bukaDetail(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          order: order,
          currentUid: widget.uid,
          isJastiper: false,
        ),
      ),
    );
  }

  Future<void> _bukaKonfirmasiPembayaran(
    Map<String, dynamic> order,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationPage(
          order: order,
          customerUid: widget.uid,
        ),
      ),
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
              'Belum Ada Pesanan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan yang kamu buat akan tampil di halaman ini.',
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

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'menunggu';
    final paymentStatus =
        order['paymentStatus'] as String? ?? 'menunggu_pembayaran';

    final orderId = order['orderId'] as String? ?? '';

    final jumlah = (order['jumlah'] as num?)?.toInt() ?? 0;
    final total = (order['totalBiayaJasa'] as num?)?.toInt() ?? 0;

    final statusColor = _statusColor(status);
    final paymentColor = _paymentStatusColor(paymentStatus);

    final bisaKonfirmasi =
        paymentStatus == 'menunggu_pembayaran' &&
        status != 'dibatalkan' &&
        status != 'ditolak';

    final bisaDibatalkan =
        status == 'menunggu' &&
        paymentStatus == 'menunggu_pembayaran';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${order['kotaAsal'] ?? '-'} → '
                  '${order['kotaTujuan'] ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Jastiper: ${order['namaJastiper'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                'Tanggal pesanan: ${_tanggal(order['createdAt'])}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$jumlah item',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _rupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Biaya jasa total',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 13),

          // STATUS PEMBAYARAN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: paymentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  paymentStatus == 'berhasil'
                      ? Icons.check_circle_outline
                      : paymentStatus == 'menunggu_verifikasi_admin'
                          ? Icons.hourglass_top_rounded
                          : Icons.account_balance_wallet_outlined,
                  color: paymentColor,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _paymentStatusLabel(paymentStatus),
                    style: TextStyle(
                      color: paymentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // TOMBOL KONFIRMASI PEMBAYARAN
          if (bisaKonfirmasi) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: orderId.isEmpty
                    ? null
                    : () => _bukaKonfirmasiPembayaran(order),
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                ),
                label: const Text('Konfirmasi Pembayaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // DETAIL DAN CHAT JASTIPER
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: orderId.isEmpty
                  ? null
                  : () => _bukaDetail(order),
              icon: const Icon(
                Icons.receipt_long_outlined,
                size: 18,
              ),
              label: const Text('Lihat Detail & Chat Jastiper'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),

          // TOMBOL PEMBATALAN
          if (bisaDibatalkan) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: orderId.isEmpty
                    ? null
                    : () => _batalkan(orderId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                    color: AppColors.error,
                  ),
                ),
                child: const Text('Batalkan Pesanan'),
              ),
            ),
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
          'Pesanan Saya',
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
                return {
                  ...doc.data(),
                  'orderId': doc.id,
                };
              }).toList() ??
              [];

          if (orders.isEmpty) return _empty();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                '${orders.length} Pesanan',
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
