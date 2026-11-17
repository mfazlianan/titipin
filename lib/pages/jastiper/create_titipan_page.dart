
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../models/titipan_model.dart';
import '../../services/titipan_service.dart';
import '../../theme/app_theme.dart';

class CreateTitipanPage extends StatefulWidget {
  final UserModel user;

  const CreateTitipanPage({
    super.key,
    required this.user,
  });

  @override
  State<CreateTitipanPage> createState() => _CreateTitipanPageState();
}

class _CreateTitipanPageState extends State<CreateTitipanPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = TitipanService();

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kotaAsalController = TextEditingController();
  final _kotaTujuanController = TextEditingController();
  final _kuotaController = TextEditingController();
  final _biayaController = TextEditingController();

  final List<String> _kategori = [
    'Fashion',
    'Makanan',
    'Beauty',
    'Oleh-oleh',
    'Elektronik',
    'Aksesoris',
    'Lainnya',
  ];

  String _selectedKategori = 'Fashion';
  DateTime? _tanggalBerangkat;
  DateTime? _tanggalPulang;
  File? _foto;
  bool _loading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kotaAsalController.dispose();
    _kotaTujuanController.dispose();
    _kuotaController.dispose();
    _biayaController.dispose();
    super.dispose();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _pilihFoto() async {
    try {
      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (result != null && mounted) {
        setState(() => _foto = File(result.path));
      }
    } catch (e) {
      _message('Gagal memilih foto: $e', error: true);
    }
  }

  Future<void> _pilihTanggal(bool berangkat) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: berangkat
          ? (_tanggalBerangkat ?? now)
          : (_tanggalPulang ??
              _tanggalBerangkat ??
              now.add(const Duration(days: 1))),
      firstDate: berangkat
          ? DateTime(now.year, now.month, now.day)
          : (_tanggalBerangkat ?? now),
      lastDate: DateTime(now.year + 3),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (berangkat) {
        _tanggalBerangkat = selected;

        if (_tanggalPulang != null &&
            _tanggalPulang!.isBefore(selected)) {
          _tanggalPulang = selected;
        }
      } else {
        _tanggalPulang = selected;
      }
    });
  }

  String _formatTanggal(DateTime? date) {
    if (date == null) return 'Pilih tanggal';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label wajib diisi';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField(String title, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _formatTanggal(date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalBerangkat == null || _tanggalPulang == null) {
      _message('Silakan tentukan tanggal perjalanan.', error: true);
      return;
    }

    if (_tanggalPulang!.isBefore(_tanggalBerangkat!)) {
      _message('Tanggal pulang tidak valid.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final titipan = TitipanModel(
        uid: widget.user.uid,
        namaJastiper: widget.user.nama,
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kotaAsal: _kotaAsalController.text.trim(),
        kotaTujuan: _kotaTujuanController.text.trim(),
        kategori: _selectedKategori,
        tanggalBerangkat: _tanggalBerangkat!,
        tanggalPulang: _tanggalPulang!,
        kuota: int.parse(_kuotaController.text.trim()),
        biayaJasa: int.parse(_biayaController.text.trim()),
      );

      await _service.createTitipan(
        titipan,
        foto: _foto,
      );

      if (!mounted) return;

      _message('Penawaran berhasil dipublikasikan!');
      Navigator.pop(context, true);
    } catch (e) {
      _message('Gagal menyimpan penawaran: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Buat Penawaran Jastip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Informasi Penawaran',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Lengkapi informasi perjalanan agar Customer dapat menemukan penawaranmu.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              'Foto Penawaran',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pilihFoto,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: _foto == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 42,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 9),
                          Text('Pilih foto dari galeri'),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_foto!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              onPressed: () {
                                setState(() => _foto = null);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 22),
            _field(
              label: 'Judul Penawaran',
              hint: 'Contoh: Jastip Fashion Bandung',
              controller: _judulController,
            ),
            const SizedBox(height: 18),
            _field(
              label: 'Deskripsi',
              hint: 'Jelaskan layanan titipanmu...',
              controller: _deskripsiController,
              maxLines: 4,
            ),
            const SizedBox(height: 18),

            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              items: _kategori.map((kategori) {
                return DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedKategori = value);
                }
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Informasi Perjalanan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Kota Asal',
              hint: 'Contoh: Bandar Lampung',
              controller: _kotaAsalController,
            ),
            const SizedBox(height: 18),
            _field(
              label: 'Kota Tujuan',
              hint: 'Contoh: Bandung',
              controller: _kotaTujuanController,
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                _dateField(
                  'Tanggal Berangkat',
                  _tanggalBerangkat,
                  () => _pilihTanggal(true),
                ),
                const SizedBox(width: 12),
                _dateField(
                  'Tanggal Pulang',
                  _tanggalPulang,
                  () => _pilihTanggal(false),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Kuota dan Biaya',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Kuota Titipan',
              hint: 'Contoh: 20',
              controller: _kuotaController,
              keyboardType: TextInputType.number,
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number < 1) {
                  return 'Kuota minimal 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _field(
              label: 'Biaya Jasa per Item (Rp)',
              hint: 'Contoh: 15000',
              controller: _biayaController,
              keyboardType: TextInputType.number,
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number < 0) {
                  return 'Biaya jasa tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),
            SizedBox(
              height: 53,
              child: ElevatedButton(
                onPressed: _loading ? null : _simpan,
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
                        'Publikasikan Penawaran',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
