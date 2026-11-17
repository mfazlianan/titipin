
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import 'order_chat_page.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String currentUid;
  final bool isJastiper;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.currentUid,
    required this.isJastiper,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _service = OrderService();

  bool _loading = false;

  String get _orderId => widget.order['orderId']?.toString() ?? '';

  String get _status => widget.order['status']?.toString() ?? 'menunggu';

  String get _otherName => widget.isJastiper
      ? widget.order['namaCustomer']?.toString() ?? 'Customer'
      : widget.order['namaJastiper']?.toString() ?? 'Jastiper';

  String get _otherUid => widget.isJastiper
      ? widget.order['customerUid']?.toString() ?? ''
      : widget.order['jastiperUid']?.toString() ?? '';

  String get _currentName => widget.isJastiper
      ? widget.order['namaJastiper']?.toString() ?? 'Jastiper'
      : widget.order['namaCustomer']?.toString() ?? 'Customer';

  String _rupiah(dynamic value) {
    final amount = (value is num ? value : 0).toInt();
    final text = amount.toString();
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

  String _date(dynamic value) {
    if (value == null) return '-';

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      try {
        date = value.toDate() as DateTime;
      } catch (_) {
        return value.toString();
      }
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
        return 'Pesanan Selesai';
      case 'ditolak':
        return 'Pesanan Ditolak';
      case 'dibatalkan':
        return 'Pesanan Dibatalkan';
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
        return Colors.red;
      case 'dalam_perjalanan':
        return Colors.blue;
      case 'diproses':
        return Colors.orange;
      case 'diterima':
        return Colors.teal;
      default:
        return Colors.amber.shade800;
    }
  }

  Future<String?> _inputReason() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Jelaskan alasan pesanan tidak dapat dipenuhi...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Kirim Penolakan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _updateStatus(String status) async {
    String reason = '';

    if (status == 'ditolak') {
      final result = await _inputReason();

      if (result == null || result.trim().isEmpty) return;

      reason = result;
    }

    if (!mounted) return;

    setState(() => _loading = true);

    try {
      await _service.updateOrderStatus(
        orderId: _orderId,
        statusBaru: status,
        alasanPenolakan: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status berhasil diubah menjadi ${_statusLabel(status)}.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openChat() async {
    if (_otherUid.isEmpty || _orderId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatPage(
          orderId: _orderId,
          currentUid: widget.currentUid,
          currentName: _currentName,
          otherName: _otherName,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _timeline() {
    final history = widget.order['riwayatStatus'];

    final items = history is List
        ? history.whereType<Map>().toList()
        : <Map>[];

    if (items.isEmpty) {
      return _section(
        title: 'Riwayat Pesanan',
        children: [
          Text('Status saat ini: ${_statusLabel(_status)}'),
        ],
      );
    }

    return _section(
      title: 'Riwayat Pesanan',
      children: [
        for (final item in items.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: _statusColor(
                    item['status']?.toString() ?? '',
                  ),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(
                          item['status']?.toString() ?? '',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((item['keterangan'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            item['keterangan'].toString(),
                          ),
                        ),
                      Text(
                        _date(item['waktu']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _jastiperActions() {
    String? nextStatus;
    String buttonText = '';

    switch (_status) {
      case 'menunggu':
        nextStatus = 'diterima';
        buttonText = 'Terima Pesanan';
        break;
      case 'diterima':
        nextStatus = 'diproses';
        buttonText = 'Mulai Proses Pesanan';
        break;
      case 'diproses':
        nextStatus = 'dalam_perjalanan';
        buttonText = 'Konfirmasi Pengiriman';
        break;
      case 'dalam_perjalanan':
        nextStatus = 'selesai';
        buttonText = 'Selesaikan Pesanan';
        break;
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return _section(
      title: 'Tindakan Jastiper',
      children: [
        if (_status == 'menunggu')
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Periksa detail permintaan, jumlah barang, tujuan, '
              'dan catatan Customer sebelum menerima pesanan.',
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () => _updateStatus(nextStatus!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(buttonText),
          ),
        ),
        if (_status == 'menunggu') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _updateStatus('ditolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tolak dengan Alasan'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _statusColor(_status).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS PESANAN',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusLabel(_status),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(_status),
                  ),
                ),
                const SizedBox(height: 5),
                Text('ID Pesanan: $_orderId'),
              ],
            ),
          ),
          _section(
            title: 'Informasi Titipan',
            children: [
              _infoRow('Nama Titipan', order['judulTitipan'] ?? '-'),
              _infoRow('Kategori', order['kategori'] ?? '-'),
              _infoRow('Kota Asal', order['kotaAsal'] ?? '-'),
              _infoRow('Kota Tujuan', order['kotaTujuan'] ?? '-'),
              _infoRow(
                'Tanggal Berangkat',
                _date(order['tanggalBerangkat']),
              ),
              _infoRow(
                'Tanggal Pulang',
                _date(order['tanggalTiba']),
              ),
            ],
          ),
          _section(
            title: 'Informasi Pemesan',
            children: [
              _infoRow(
                widget.isJastiper ? 'Customer' : 'Jastiper',
                _otherName,
              ),
              _infoRow(
                'Jumlah Pesanan',
                '${order['jumlah'] ?? 0}',
              ),
              _infoRow(
                'Biaya Jasa per Item',
                _rupiah(order['biayaJasa']),
              ),
              _infoRow(
                'Total Biaya Jasa',
                _rupiah(order['totalBiayaJasa']),
              ),
              _infoRow(
                'Tanggal Pemesanan',
                _date(order['createdAt']),
              ),
            ],
          ),
          _section(
            title: 'Catatan Customer',
            children: [
              Text(
                (order['catatan'] ?? '').toString().isEmpty
                    ? 'Tidak ada catatan.'
                    : order['catatan'].toString(),
              ),
            ],
          ),
          _section(
            title: 'Informasi Pembayaran',
            children: [
              _infoRow(
                'Metode Pembayaran',
                order['paymentMethod']?.toString() ?? 'Transfer Bank',
              ),
              _infoRow(
                'Bank Tujuan',
                order['paymentBank']?.toString() ?? 'SeaBank',
              ),
              _infoRow(
                'Nominal Pembayaran',
                _rupiah(order['paymentAmount']),
              ),
              _infoRow(
                'Status Pembayaran',
                (order['paymentStatus'] ?? 'menunggu_pembayaran')
                    .toString()
                    .replaceAll('_', ' '),
              ),
            ],
          ),
          if (_status == 'ditolak')
            _section(
              title: 'Alasan Penolakan',
              children: [
                Text(
                  order['alasanPenolakan']?.toString() ??
                      'Tidak ada keterangan.',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          _timeline(),
          _jastiperActions(),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('Chat dengan $_otherName'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
