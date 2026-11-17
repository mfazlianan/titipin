
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/titipan_model.dart';
import '../../models/user_model.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class CreateOrderPage extends StatefulWidget {
  final TitipanModel titipan;
  final UserModel user;

  const CreateOrderPage({
    super.key,
    required this.titipan,
    required this.user,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController(text: '1');
  final _catatanController = TextEditingController();
  final _passwordController = TextEditingController();

  final OrderService _orderService = OrderService();

  bool _loading = false;
  bool _obscurePassword = true;

  static const String _bankName = 'SeaBank';
  static const String _bankAccountNumber = '2312115799';
  static const String _bankAccountName = 'M Fazli Anan';

  int get _jumlah => int.tryParse(_jumlahController.text) ?? 0;

  int get _totalBiaya => _jumlah * widget.titipan.biayaJasa;

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _rupiah(int value) {
    final text = value.toString();
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

  Future<void> _buatPesanan() async {
    if (!_formKey.currentState!.validate()) return;

    final titipan = widget.titipan;

    if (!titipan.tersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penawaran ini sudah tidak tersedia.'),
        ),
      );
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login berakhir. Silakan login kembali.'),
        ),
      );
      return;
    }

    if (firebaseUser.uid != widget.user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun pengguna tidak sesuai. Silakan login kembali.'),
        ),
      );
      return;
    }

    final email = firebaseUser.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email akun tidak tersedia untuk verifikasi password.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Verifikasi ulang password melalui Firebase Authentication.
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      if (!mounted) return;

      _passwordController.clear();

      // Membuat pesanan dengan parameter sesuai OrderService.
      final orderId = await _orderService.createOrder(
        titipanId: titipan.id,
        customerUid: widget.user.uid,
        namaCustomer: widget.user.nama,
        jastiperUid: titipan.uid,
        namaJastiper: titipan.namaJastiper,
        judulTitipan: titipan.judul,
        fotoUrl: titipan.fotoUrl,
        kotaAsal: titipan.kotaAsal,
        kotaTujuan: titipan.kotaTujuan,
        kategori: titipan.kategori,
        tanggalBerangkat: titipan.tanggalBerangkat,
        tanggalTiba: titipan.tanggalPulang,
        biayaJasa: titipan.biayaJasa,
        jumlah: _jumlah,
        catatan: _catatanController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          title: const Text('Pesanan Berhasil Dibuat!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pesananmu sudah tersimpan. Silakan lakukan transfer sesuai rincian berikut.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total biaya jasa',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _rupiah(_totalBiaya),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Transfer ke rekening SeaBank yang tertera pada halaman pembayaran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status pembayaran: Menunggu Pembayaran',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, orderId);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Password akun yang kamu masukkan salah.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
          break;
        case 'user-mismatch':
          message = 'Akun tidak sesuai. Silakan login kembali.';
          break;
        case 'user-not-found':
          message = 'Akun tidak ditemukan. Silakan login kembali.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah. Periksa jaringanmu.';
          break;
        default:
          message = 'Verifikasi akun gagal: ${e.message ?? e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pesanan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titipan = widget.titipan;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penawaran yang Dipilih',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: titipan.fotoUrl.isEmpty
                              ? Container(
                                  color: AppColors.primaryLight,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Image.network(
                                  titipan.fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: AppColors.primaryLight,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titipan.judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${titipan.kotaAsal} → ${titipan.kotaTujuan}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_rupiah(titipan.biayaJasa)} / item',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25),
                  Text(
                    'Kuota tersedia: ${titipan.sisaKuota} item',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Informasi Pemesan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.nama.isEmpty ? 'Customer' : widget.user.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Jumlah Titipan'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah barang',
                prefixIcon: const Icon(Icons.shopping_basket_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              validator: (value) {
                final jumlah = int.tryParse(value ?? '');

                if (jumlah == null || jumlah < 1) {
                  return 'Masukkan jumlah minimal 1.';
                }

                if (jumlah > titipan.sisaKuota) {
                  return 'Melebihi kuota tersedia (${titipan.sisaKuota}).';
                }

                return null;
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('Catatan untuk Jastiper'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _catatanController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Contoh: warna hitam, ukuran M...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Metode Pembayaran'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer Bank',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pembayaran melalui transfer bank',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekening Tujuan Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _bankName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Nomor Rekening',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _bankAccountNumber,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Nama Pemilik Rekening',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    _bankAccountName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Silakan transfer setelah pesanan berhasil dibuat. Simpan bukti transfer untuk proses konfirmasi pembayaran.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Rincian Pembayaran'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biaya jasa per item'),
                      Text(_rupiah(titipan.biayaJasa)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah barang'),
                      Text('$_jumlah item'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total biaya jasa',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _rupiah(_totalBiaya),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nominal ini merupakan biaya jasa jastiper, belum termasuk harga barang dan biaya lain jika ada.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Konfirmasi Keamanan Akun'),
            const SizedBox(height: 8),
            const Text(
              'Masukkan password akun Titipin untuk memverifikasi bahwa pesanan dibuat oleh pemilik akun.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'Masukkan password akun',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password akun wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 9),
            const Text(
              'Password hanya digunakan untuk verifikasi Firebase dan tidak disimpan.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 53,
              child: ElevatedButton(
                onPressed: _loading ? null : _buatPesanan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Verifikasi & Buat Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
