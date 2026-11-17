
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String customerUid;

  const PaymentConfirmationPage({
    super.key,
    required this.order,
    required this.customerUid,
  });

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState
    extends State<PaymentConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = OrderService();

  final _namaController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _nominalController = TextEditingController();
  final _referensiController = TextEditingController();

  bool _loading = false;

  static const String _bank = 'SeaBank';
  static const String _rekening = '2312115799';
  static const String _pemilik = 'M Fazli Anan';

  int get _tagihan {
    return (widget.order['paymentAmount'] as num?)?.toInt() ??
        (widget.order['totalBiayaJasa'] as num?)?.toInt() ??
        0;
  }

  String _rupiah(int value) {
    final text = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      result.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp${result.toString()}';
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (selected != null) {
      _tanggalController.text =
          '${selected.day.toString().padLeft(2, '0')}/'
          '${selected.month.toString().padLeft(2, '0')}/'
          '${selected.year}';
    }
  }

  Future<void> _kirimKonfirmasi() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = int.tryParse(
      _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
    );

    if (nominal == null || nominal != _tagihan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal harus sesuai tagihan ${_rupiah(_tagihan)}.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.submitPaymentConfirmation(
        orderId: widget.order['orderId']?.toString() ?? '',
        customerUid: widget.customerUid,
        namaPengirim: _namaController.text,
        tanggalTransfer: _tanggalController.text,
        nominalTransfer: nominal,
        nomorReferensi: _referensiController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
          title: const Text('Konfirmasi Terkirim'),
          content: const Text(
            'Informasi pembayaran berhasil dikirim. '
            'Pembayaran akan diperiksa admin melalui mutasi rekening. '
            'Pesanan belum dianggap lunas sampai admin menyetujuinya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: onTap != null
                ? const Icon(Icons.calendar_month_outlined)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label wajib diisi.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _rekeningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF087E65),
            Color(0xFF064E45),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRANSFER PEMBAYARAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            _bank,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Nomor Rekening',
            style: TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _rekening,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Salin nomor rekening secara manual.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Atas Nama',
            style: TextStyle(color: Colors.white70),
          ),
          const Text(
            _pemilik,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(color: Colors.white38, height: 28),
          const Text(
            'Total yang harus ditransfer',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            _rupiah(_tagihan),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Nominal ini merupakan biaya jasa sesuai pesanan.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalController.dispose();
    _nominalController.dispose();
    _referensiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rekeningCard(),
                const SizedBox(height: 22),
                const Text(
                  'Informasi Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _field(
                  label: 'Nama Pengirim',
                  controller: _namaController,
                  hint: 'Masukkan nama pemilik rekening',
                ),
                const SizedBox(height: 15),
                _field(
                  label: 'Tanggal Transfer',
                  controller: _tanggalController,
                  hint: 'Pilih tanggal transfer',
                  readOnly: true,
                  onTap: _pilihTanggal,
                ),
                const SizedBox(height: 15),
                _field(
                  label: 'Nominal Transfer',
                  controller: _nominalController,
                  hint: 'Contoh: 250000',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _field(
                  label: 'Nomor Referensi Transaksi',
                  controller: _referensiController,
                  hint: 'Masukkan nomor referensi transfer',
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan kamu sudah benar-benar melakukan '
                          'transfer. Admin akan mencocokkan data '
                          'dengan mutasi rekening sebelum pembayaran '
                          'dinyatakan berhasil.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _kirimKonfirmasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Kirim Konfirmasi Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
