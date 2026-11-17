
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class JastiperProfilePage extends StatefulWidget {
  final UserModel user;

  const JastiperProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<JastiperProfilePage> createState() =>
      _JastiperProfilePageState();
}

class _JastiperProfilePageState extends State<JastiperProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late final TextEditingController _namaController;
  late final TextEditingController _teleponController;
  late final TextEditingController _usernameController;
  late final TextEditingController _namaLayananController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _whatsappController;

  bool _isLoading = false;

  final List<String> _kategoriOptions = [
    'Makanan & Minuman',
    'Fashion',
    'Kosmetik',
    'Elektronik',
    'Aksesoris',
    'Kebutuhan Rumah',
    'Obat & Kesehatan',
    'Dokumen',
    'Lainnya',
  ];

  final List<String> _wilayahOptions = [
    'Bandar Lampung',
    'Lampung Selatan',
    'Lampung Tengah',
    'Lampung Timur',
    'Metro',
    'Pesawaran',
    'Pringsewu',
    'Tanggamus',
    'Lampung Utara',
    'Lampung Barat',
    'Tulang Bawang',
    'Way Kanan',
    'Mesuji',
    'Pesisir Barat',
    'Tulang Bawang Barat',
    'Seluruh Indonesia',
  ];

  late List<String> _selectedCategories;
  late List<String> _selectedAreas;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.user.nama);
    _teleponController =
        TextEditingController(text: widget.user.nomorTelepon);
    _usernameController =
        TextEditingController(text: widget.user.username);
    _namaLayananController =
        TextEditingController(text: widget.user.namaLayanan);
    _deskripsiController =
        TextEditingController(text: widget.user.deskripsiLayanan);
    _whatsappController =
        TextEditingController(text: widget.user.nomorWhatsapp);

    _selectedCategories = List<String>.from(
      widget.user.kategoriLayanan,
    );

    _selectedAreas = List<String>.from(
      widget.user.wilayahLayanan,
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _usernameController.dispose();
    _namaLayananController.dispose();
    _deskripsiController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      _showMessage('Pilih minimal satu kategori layanan.', isError: true);
      return;
    }

    if (_selectedAreas.isEmpty) {
      _showMessage('Pilih minimal satu wilayah layanan.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan identitas dasar akun.
      await _userService.updateProfile(
        uid: widget.user.uid,
        nama: _namaController.text.trim(),
        nomorTelepon: _teleponController.text.trim(),
      );

      // Simpan informasi layanan Jastiper.
      await _userService.updateJastiperProfile(
        uid: widget.user.uid,
        username: _usernameController.text
            .trim()
            .replaceAll('@', ''),
        namaLayanan: _namaLayananController.text.trim(),
        deskripsiLayanan: _deskripsiController.text.trim(),
        nomorWhatsapp: _whatsappController.text.trim(),
        kategoriLayanan: _selectedCategories,
        wilayahLayanan: _selectedAreas,
      );

      if (!mounted) return;

      _showMessage('Profil Jastiper berhasil diperbarui.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menyimpan profil: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint ?? 'Masukkan $label',
              prefixIcon: Icon(icon, size: 20),
              filled: true,
              fillColor: AppColors.primaryLight.withValues(alpha: 0.12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selected,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);

            return FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: true,
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => onToggle(option),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Icons.storefront_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Jastiper',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bangun kepercayaan pelanggan melalui profil layananmu.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profil Jastiper',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccountHeader(),

                    const SizedBox(height: 25),

                    _sectionTitle(
                      'Informasi Pemilik',
                      'Informasi dasar akun Jastiper kamu.',
                    ),

                    _buildField(
                      label: 'Nama Lengkap',
                      controller: _namaController,
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi.';
                        }
                        return null;
                      },
                    ),

                    _buildField(
                      label: 'Nomor Telepon',
                      controller: _teleponController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const Divider(height: 30),

                    _sectionTitle(
                      'Identitas Layanan',
                      'Buat identitas layanan yang mudah dikenali pelanggan.',
                    ),

                    _buildField(
                      label: 'Username',
                      controller: _usernameController,
                      icon: Icons.alternate_email,
                      hint: 'Contoh: jastiper_fazli',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username wajib diisi.';
                        }
                        return null;
                      },
                    ),

                    _buildField(
                      label: 'Nama Toko / Layanan',
                      controller: _namaLayananController,
                      icon: Icons.storefront_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama layanan wajib diisi.';
                        }
                        return null;
                      },
                    ),

                    _buildField(
                      label: 'Deskripsi Layanan',
                      controller: _deskripsiController,
                      icon: Icons.description_outlined,
                      hint: 'Ceritakan layanan jastip yang kamu tawarkan...',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Deskripsi layanan wajib diisi.';
                        }
                        return null;
                      },
                    ),

                    _buildField(
                      label: 'Nomor WhatsApp',
                      controller: _whatsappController,
                      icon: Icons.chat_outlined,
                      hint: 'Contoh: 081234567890',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor WhatsApp wajib diisi.';
                        }
                        return null;
                      },
                    ),

                    const Divider(height: 30),

                    _sectionTitle(
                      'Kategori dan Wilayah',
                      'Pilih kategori dan area yang dapat kamu layani.',
                    ),

                    _buildMultiSelect(
                      title: 'Kategori Layanan',
                      subtitle: 'Kamu dapat memilih lebih dari satu kategori.',
                      options: _kategoriOptions,
                      selected: _selectedCategories,
                      onToggle: (value) {
                        setState(() {
                          if (_selectedCategories.contains(value)) {
                            _selectedCategories.remove(value);
                          } else {
                            _selectedCategories.add(value);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    _buildMultiSelect(
                      title: 'Wilayah Layanan',
                      subtitle: 'Pilih area tempat kamu menerima titipan.',
                      options: _wilayahOptions,
                      selected: _selectedAreas,
                      onToggle: (value) {
                        setState(() {
                          if (_selectedAreas.contains(value)) {
                            _selectedAreas.remove(value);
                          } else {
                            _selectedAreas.add(value);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 19,
                                width: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isLoading
                              ? 'Menyimpan...'
                              : 'Simpan Profil Jastiper',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
