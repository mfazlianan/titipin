
import 'package:flutter/material.dart';

import '../../models/titipan_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'create_order_page.dart';

class TitipanDetailPage extends StatelessWidget {
  final TitipanModel titipan;
  final UserModel user;

  const TitipanDetailPage({
    super.key,
    required this.titipan,
    required this.user,
  });

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

  String _tanggal(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateOrder(BuildContext context) {
    if (!titipan.tersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, penawaran ini sudah tidak tersedia.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderPage(
          titipan: titipan,
          user: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Detail Penawaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openCreateOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                titipan.tersedia ? 'Pesan Titipan' : 'Penawaran Tidak Tersedia',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 25),
        children: [
          SizedBox(
            height: 245,
            width: double.infinity,
            child: titipan.fotoUrl.isNotEmpty
                ? Image.network(
                    titipan.fotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 55,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 65,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    titipan.kategori,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  titipan.judul,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Jastiper: ${titipan.namaJastiper}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biaya Jasa per Item',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _rupiah(titipan.biayaJasa),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Informasi Perjalanan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 17),
                _infoItem(
                  icon: Icons.flight_takeoff_rounded,
                  title: 'Kota Asal',
                  value: titipan.kotaAsal,
                ),
                _infoItem(
                  icon: Icons.location_on_outlined,
                  title: 'Kota Tujuan',
                  value: titipan.kotaTujuan,
                ),
                _infoItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Tanggal Berangkat',
                  value: _tanggal(titipan.tanggalBerangkat),
                ),
                _infoItem(
                  icon: Icons.event_available_outlined,
                  title: 'Tanggal Pulang',
                  value: _tanggal(titipan.tanggalPulang),
                ),
                _infoItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Kuota Tersedia',
                  value: '${titipan.sisaKuota} dari ${titipan.kuota} item',
                ),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 18),
                const Text(
                  'Deskripsi Penawaran',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  titipan.deskripsi.isEmpty
                      ? 'Belum ada deskripsi penawaran.'
                      : titipan.deskripsi,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6EE),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Periksa informasi penawaran dan biaya sebelum melakukan pemesanan.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: Color(0xFF27643C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
