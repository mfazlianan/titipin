
import 'package:flutter/material.dart';

import '../../models/titipan_model.dart';
import '../../models/user_model.dart';
import '../../services/titipan_service.dart';
import '../../theme/app_theme.dart';
import 'create_titipan_page.dart';

class MyTitipanPage extends StatefulWidget {
  final UserModel user;

  const MyTitipanPage({
    super.key,
    required this.user,
  });

  @override
  State<MyTitipanPage> createState() => _MyTitipanPageState();
}

class _MyTitipanPageState extends State<MyTitipanPage> {
  final TitipanService _service = TitipanService();

  late final Stream<List<TitipanModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _service.getMyTitipan(widget.user.uid);
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

  String _tanggal(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _tambah() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTitipanPage(user: widget.user),
      ),
    );
  }

  Future<void> _ubahStatus(TitipanModel item) async {
    final statusBaru =
        item.status == 'aktif' ? 'nonaktif' : 'aktif';

    if (statusBaru == 'aktif' &&
        item.kuotaTerisi >= item.kuota) {
      _message('Kuota penawaran sudah penuh.', true);
      return;
    }

    try {
      await _service.updateStatus(
        id: item.id,
        uid: widget.user.uid,
        status: statusBaru,
      );

      _message('Status penawaran berhasil diperbarui.');
    } catch (e) {
      _message('Gagal mengubah status: $e', true);
    }
  }

  Future<void> _hapus(TitipanModel item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penawaran?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${item.judul}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await _service.deleteTitipan(
        id: item.id,
        uid: widget.user.uid,
        fotoUrl: item.fotoUrl,
      );

      _message('Penawaran berhasil dihapus.');
    } catch (e) {
      _message('Gagal menghapus penawaran: $e', true);
    }
  }

  void _message(String message, [bool error = false]) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Widget _tag(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card(TitipanModel item) {
    final aktif = item.status == 'aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.fotoUrl.isNotEmpty)
            Image.network(
              item.fotoUrl,
              width: double.infinity,
              height: 165,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: AppColors.primaryLight,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            )
          else
            Container(
              height: 110,
              width: double.infinity,
              color: AppColors.primaryLight,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 42,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.judul,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'status') {
                          _ubahStatus(item);
                        } else if (value == 'hapus') {
                          _hapus(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'status',
                          child: Text(
                            aktif ? 'Nonaktifkan' : 'Aktifkan',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _tag(item.kategori, AppColors.primary),
                    _tag(
                      item.status.toUpperCase(),
                      aktif ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${item.kotaAsal} → ${item.kotaTujuan}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_tanggal(item.tanggalBerangkat)} - '
                      '${_tanggal(item.tanggalPulang)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biaya jasa / item',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rupiah(item.biayaJasa),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Kuota tersedia',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.sisaKuota}/${item.kuota}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 65,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Penawaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat penawaran perjalanan pertamamu agar Customer dapat menemukan layananmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _tambah,
              icon: const Icon(Icons.add),
              label: const Text('Buat Penawaran'),
            ),
          ],
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
          'Penawaran Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambah,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Penawaran'),
      ),
      body: StreamBuilder<List<TitipanModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat penawaran: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) return _empty();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
            children: [
              Text(
                '${items.length} Penawaran',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(_card),
            ],
          );
        },
      ),
    );
  }
}
