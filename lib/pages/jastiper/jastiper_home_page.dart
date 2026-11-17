
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/titipan_model.dart';
import '../../services/auth_service.dart';
import '../../services/titipan_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../mode/mode_selection_page.dart';
import 'create_titipan_page.dart';
import 'my_titipan_page.dart';
import 'jastiper_orders_page.dart';
import 'jastiper_profile_page.dart';

class JastiperHomePage extends StatefulWidget {
  final UserModel user;

  const JastiperHomePage({
    super.key,
    required this.user,
  });

  @override
  State<JastiperHomePage> createState() => _JastiperHomePageState();
}

class _JastiperHomePageState extends State<JastiperHomePage> {
  final TitipanService _titipanService = TitipanService();
  final OrderService _orderService = OrderService();

  late final Stream<List<TitipanModel>> _titipanStream;
  late final Stream _orderStream;

  @override
  void initState() {
    super.initState();

    _titipanStream = _titipanService.getMyTitipan(widget.user.uid);
    _orderStream = _orderService.getJastiperOrders(widget.user.uid);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCreateTitipan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTitipanPage(user: widget.user),
      ),
    );
  }

  Future<void> _openMyTitipan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyTitipanPage(user: widget.user),
      ),
    );
  }

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JastiperOrdersPage(
          uid: widget.user.uid,
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JastiperProfilePage(
          user: widget.user,
        ),
      ),
    );
  }

  void _openModeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModeSelectionPage(user: widget.user),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
    } catch (e) {
      _showMessage('Gagal keluar dari akun: $e');
    }
  }

  Widget _buildHeader() {
    final nama = widget.user.nama.trim().isEmpty
        ? 'Jastiper'
        : widget.user.nama.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $nama 👋',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola perjalanan dan layanan titipanmu di sini.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 16),
          const Text(
            'Kembangkan Layanan Jastipmu!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat penawaran perjalanan dan bantu Customer mendapatkan produk dari berbagai kota.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openCreateTitipan,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Penawaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(
    List<TitipanModel> items,
    int orderCount,
  ) {
    final total = items.length;
    final aktif = items.where((item) => item.status == 'aktif').length;
    final nonaktif =
        items.where((item) => item.status == 'nonaktif').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Aktivitas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildStatCard(
              title: 'Total Penawaran',
              value: total.toString(),
              icon: Icons.shopping_bag_rounded,
              color: AppColors.primary,
              subtitle: 'Semua penawaran',
            ),
            _buildStatCard(
              title: 'Penawaran Aktif',
              value: aktif.toString(),
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              subtitle: 'Sedang ditampilkan',
            ),
            _buildStatCard(
              title: 'Penawaran Nonaktif',
              value: nonaktif.toString(),
              icon: Icons.pause_circle_filled_rounded,
              color: Colors.orange,
              subtitle: 'Tidak ditampilkan',
            ),
            _buildStatCard(
              title: 'Pesanan Masuk',
              value: orderCount < 0 ? '-' : orderCount.toString(),
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
              subtitle: 'Pesanan dari Customer',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    List<TitipanModel> items,
    int orderCount,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildBanner(),
        const SizedBox(height: 28),
        _buildStatistics(items, orderCount),
        const SizedBox(height: 28),
        const Text(
          'Kelola Layanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Profil Saya',
          description:
              'Lengkapi identitas, informasi toko, kategori, dan wilayah layananmu.',
          icon: Icons.storefront_rounded,
          onTap: _openProfile,
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Buat Penawaran Jastip',
          description:
              'Tambahkan perjalanan baru agar Customer dapat menitipkan barang.',
          icon: Icons.add_shopping_cart_rounded,
          onTap: _openCreateTitipan,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Penawaran Saya',
          description:
              'Lihat, aktifkan, nonaktifkan, dan hapus penawaranmu.',
          icon: Icons.inventory_2_rounded,
          onTap: _openMyTitipan,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Pesanan Masuk',
          description:
              'Lihat pesanan Customer, konfirmasi, dan kelola proses pengiriman.',
          icon: Icons.receipt_long_rounded,
          onTap: _openOrders,
          color: Colors.orange,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tips: Lengkapi judul, deskripsi, foto, dan jadwal perjalanan agar penawaranmu lebih mudah ditemukan Customer.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
            ),
            SizedBox(width: 9),
            Text(
              'Titipin Partner',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profil Saya',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
          IconButton(
            tooltip: 'Ganti mode',
            onPressed: _openModeSelection,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<TitipanModel>>(
          stream: _titipanStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final items = snapshot.data ?? [];

            return StreamBuilder(
              stream: _orderStream,
              builder: (context, orderSnapshot) {
                final orderCount = orderSnapshot.hasError
                    ? -1
                    : orderSnapshot.data?.docs.length ?? 0;

                return _buildDashboard(items, orderCount);
              },
            );
          },
        ),
      ),
    );
  }
}
