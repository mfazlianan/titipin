
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class CustomerProfilePage extends StatefulWidget {
  final UserModel user;

  const CustomerProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState
    extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final UserService _userService = UserService();

  late final TextEditingController _namaController;
  late final TextEditingController _teleponController;
  late final TextEditingController _alamatController;
  late final TextEditingController _kotaController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _namaController =
        TextEditingController(text: widget.user.nama);

    _teleponController =
        TextEditingController(text: widget.user.nomorTelepon);

    _alamatController =
        TextEditingController(text: widget.user.alamat);

    _kotaController =
        TextEditingController(text: widget.user.kotaDomisili);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _kotaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateProfile(
        uid: widget.user.uid,
        nama: _namaController.text.trim(),
        nomorTelepon: _teleponController.text.trim(),
        alamat: _alamatController.text.trim(),
        kotaDomisili: _kotaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: requiredField
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label wajib diisi';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          initialValue: widget.user.email,
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
              size: 21,
            ),
            filled: true,
            fillColor: const Color(0xFFF0F1F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Email digunakan sebagai identitas akun dan tidak dapat diubah dari halaman ini.',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white70,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            _namaController.text.trim().isEmpty
                ? 'Customer Titipin'
                : _namaController.text.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Profil Customer',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
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
          'Profil Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 25),

              const Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                controller: _namaController,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 17),

              _buildEmailField(),
              const SizedBox(height: 17),

              _buildTextField(
                label: 'Nomor Telepon',
                hint: 'Contoh: 081234567890',
                controller: _teleponController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 17),

              _buildTextField(
                label: 'Alamat Lengkap',
                hint: 'Masukkan alamat rumah atau tempat tinggal',
                controller: _alamatController,
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 17),

              _buildTextField(
                label: 'Kota Domisili',
                hint: 'Contoh: Bandar Lampung',
                controller: _kotaController,
                icon: Icons.location_city_rounded,
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'Menyimpan...'
                        : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
