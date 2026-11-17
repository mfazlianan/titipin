
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class ModeSelectionPage extends StatefulWidget {
  final UserModel user;

  const ModeSelectionPage({
    super.key,
    required this.user,
  });

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage> {
  final UserService _userService = UserService();

  bool _isLoading = false;

  Future<void> _changeMode(String mode) async {
    if (widget.user.activeMode == mode) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userService.updateActiveMode(
        widget.user.uid,
        mode,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengganti mode: $e'),
          backgroundColor: AppColors.error,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Widget _modeCard({
    required String title,
    required String description,
    required String mode,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    final isActive = widget.user.activeMode == mode;

    return InkWell(
      onTap: _isLoading ? null : () => _changeMode(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 29,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                    size: 24,
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
                fontSize: 13,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 13),
              const Text(
                'Mode sedang digunakan',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mode'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 10),
              const Text(
                'Mau menggunakan Titipin sebagai apa?',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kamu bisa berganti mode kapan saja. Satu akun tetap bisa digunakan untuk keduanya.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              _modeCard(
                title: 'Customer',
                description:
                    'Temukan berbagai produk menarik dari jastiper di berbagai kota dan lakukan pemesanan dengan mudah.',
                mode: 'customer',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.primary,
                background: AppColors.primaryLight,
              ),
              const SizedBox(height: 18),
              _modeCard(
                title: 'Jastiper',
                description:
                    'Tawarkan jasa titip, buat perjalanan, tambahkan produk, dan dapatkan pesanan dari customer.',
                mode: 'jastiper',
                icon: Icons.storefront_rounded,
                color: AppColors.secondary,
                background: const Color(0xFFE8F6EE),
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'Satu akun. Dua peluang. Tanpa batas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
