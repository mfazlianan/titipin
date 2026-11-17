
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/titipan_model.dart';
import '../../services/auth_service.dart';
import '../../services/titipan_service.dart';
import '../../theme/app_theme.dart';
import '../mode/mode_selection_page.dart';
import 'titipan_detail_page.dart';
import 'customer_orders_page.dart';
import 'customer_profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  final UserModel user;

  const CustomerHomePage({
    super.key,
    required this.user,
  });

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final TitipanService _titipanService = TitipanService();

  final TextEditingController _searchController =
      TextEditingController();

  final GlobalKey _marketplaceKey = GlobalKey();

  late final Stream<List<TitipanModel>> _titipanStream;

  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<_CategoryData> _categories = [
    _CategoryData(
      title: 'Semua',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFEAF1FF),
    ),
    _CategoryData(
      title: 'Fashion',
      icon: Icons.checkroom_rounded,
      color: Color(0xFFEAF1FF),
    ),
    _CategoryData(
      title: 'Makanan',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFF0E6),
    ),
    _CategoryData(
      title: 'Beauty',
      icon: Icons.face_retouching_natural,
      color: Color(0xFFFFEAF2),
    ),
    _CategoryData(
      title: 'Oleh-oleh',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFE8F6EE),
    ),
    _CategoryData(
      title: 'Elektronik',
      icon: Icons.devices_rounded,
      color: Color(0xFFF0EAFF),
    ),
    _CategoryData(
      title: 'Aksesoris',
      icon: Icons.watch_rounded,
      color: Color(0xFFFFF5DF),
    ),
    _CategoryData(
      title: 'Lainnya',
      icon: Icons.category_rounded,
      color: Color(0xFFE9F4F5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _titipanStream = _titipanService.getAllTitipan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Membuka halaman pemilihan mode.
  void _openModeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModeSelectionPage(user: widget.user),
      ),
    );
  }

  // Membuka halaman Profil Customer.
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerProfilePage(
          user: widget.user,
        ),
      ),
    );
  }

  // Membuka halaman Pesanan Saya.
  void _openCustomerOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerOrdersPage(
          uid: widget.user.uid,
        ),
      ),
    );
  }

  // Logout akun.
  Future<void> _logout() async {
    try {
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar dari akun: $e'),
        ),
      );
    }
  }

  // Fungsi tombol Jelajahi Sekarang.
  void _exploreNow() {
    setState(() {
      _selectedCategory = 'Semua';
      _searchController.clear();
      _searchQuery = '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final marketplaceContext =
          _marketplaceKey.currentContext;

      if (marketplaceContext != null) {
        Scrollable.ensureVisible(
          marketplaceContext,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
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

  // Filter kategori dan pencarian.
  List<TitipanModel> _filterTitipan(
    List<TitipanModel> items,
  ) {
    return items.where((item) {
      final categoryMatch = _selectedCategory == 'Semua' ||
          item.kategori.toLowerCase() ==
              _selectedCategory.toLowerCase();

      final query = _searchQuery.toLowerCase();

      final searchMatch = query.isEmpty ||
          item.judul.toLowerCase().contains(query) ||
          item.deskripsi.toLowerCase().contains(query) ||
          item.kotaAsal.toLowerCase().contains(query) ||
          item.kotaTujuan.toLowerCase().contains(query) ||
          item.namaJastiper.toLowerCase().contains(query) ||
          item.kategori.toLowerCase().contains(query);

      return categoryMatch && searchMatch && item.tersedia;
    }).toList();
  }

  // Membuka detail penawaran.
  void _openDetail(TitipanModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TitipanDetailPage(
          titipan: item,
          user: widget.user,
        ),
      ),
    );
  }

  // Header utama.
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titipin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Marketplace Jasa Titip',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Profil Saya',
          onPressed: _openProfile,
          icon: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.primary,
          ),
        ),

        IconButton(
          tooltip: 'Pesanan Saya',
          onPressed: _openCustomerOrders,
          icon: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
          ),
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
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${widget.user.nama.isEmpty ? 'Customer' : widget.user.nama} 👋',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mau titip sesuatu dari kota mana hari ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Kolom pencarian.
  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Cari produk, kota, atau jastiper...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.primary,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Banner marketplace.
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
      child: Stack(
        children: [
          Positioned(
            right: -5,
            bottom: -12,
            child: Icon(
              Icons.travel_explore_rounded,
              size: 115,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TITIPIN MARKETPLACE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Jelajahi Jastip\nFavoritmu!',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.2,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Temukan produk unik dari berbagai kota bersama jastiper terpercaya.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 17),
              ElevatedButton(
                onPressed: _exploreNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Jelajahi Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Kategori.
  Widget _buildCategories() {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category.title;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.title;
              });
            },
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 61,
                    height: 61,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : category.color,
                      borderRadius: BorderRadius.circular(18),
                      border: selected
                          ? Border.all(
                              color: AppColors.primaryDark,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      category.icon,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penawaran Jastip',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Temukan penawaran menarik dari jastiper',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count tersedia',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  // Kartu penawaran.
  Widget _buildOfferCard(TitipanModel item) {
    return InkWell(
      onTap: () => _openDetail(item),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 135,
                  width: double.infinity,
                  child: item.fotoUrl.isNotEmpty
                      ? Image.network(
                          item.fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.kategori,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.kotaAsal} → ${item.kotaTujuan}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.namaJastiper,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    _rupiah(item.biayaJasa),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Biaya jasa / item',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Sisa kuota: ${item.sisaKuota}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.primary,
          size: 42,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Penawaran Belum Ditemukan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Coba gunakan kata kunci lain atau pilih kategori yang berbeda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'Semua';
              });
            },
            child: const Text('Reset pencarian'),
          ),
        ],
      ),
    );
  }

  // Marketplace dan daftar penawaran.
  Widget _buildMarketplace() {
    return StreamBuilder<List<TitipanModel>>(
      stream: _titipanStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Gagal memuat penawaran: ${snapshot.error}',
              style: const TextStyle(
                color: AppColors.error,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(35),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final allItems = snapshot.data ?? [];
        final filteredItems = _filterTitipan(allItems);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(filteredItems.length),
            const SizedBox(height: 15),
            if (filteredItems.isEmpty)
              _buildEmpty()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 750 ? 3 : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    itemBuilder: (context, index) {
                      return _buildOfferCard(
                        filteredItems[index],
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            15,
            18,
            25,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildGreeting(),
            const SizedBox(height: 18),
            _buildSearch(),
            const SizedBox(height: 22),
            _buildBanner(),
            const SizedBox(height: 27),
            const Text(
              'Kategori Pilihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 15),
            _buildCategories(),
            const SizedBox(height: 25),
            Container(
              key: _marketplaceKey,
              child: _buildMarketplace(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryData({
    required this.title,
    required this.icon,
    required this.color,
  });
}
