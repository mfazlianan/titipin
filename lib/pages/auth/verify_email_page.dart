
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final AuthService _authService = AuthService();

  bool _isChecking = false;
  bool _isSending = false;

  String? _message;
  bool _messageIsError = false;

  String get _email {
    return FirebaseAuth.instance.currentUser?.email ?? 'Email pengguna';
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final isVerified = await _authService.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        setState(() {
          _message = 'Email berhasil diverifikasi. Memuat akun kamu...';
          _messageIsError = false;
        });

        // AuthGate mendengarkan userChanges().
        // Setelah reload, AuthGate akan mengarahkan ke halaman utama.
      } else {
        setState(() {
          _message =
              'Email belum terverifikasi. Silakan buka email dan tekan tautan verifikasi terlebih dahulu.';
          _messageIsError = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.message ?? 'Gagal memeriksa status verifikasi.';
        _messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Terjadi kesalahan: $e';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await _authService.resendVerificationEmail();

      if (!mounted) return;

      setState(() {
        _message = 'Email verifikasi berhasil dikirim ulang. '
            'Periksa kotak masuk atau folder spam kamu.';
        _messageIsError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'too-many-requests':
          message = 'Terlalu banyak permintaan. Tunggu beberapa saat.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah.';
          break;
        default:
          message = e.message ?? 'Gagal mengirim ulang email.';
      }

      setState(() {
        _message = message;
        _messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 58,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Verifikasi Email Kamu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Satu langkah lagi! Kami telah mengirimkan tautan '
                    'verifikasi ke alamat email berikut.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Silakan buka aplikasi email kamu, cari pesan '
                    'dari Firebase, kemudian tekan tombol verifikasi '
                    'di dalam email tersebut.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkVerification,
                      icon: _isChecking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(
                        _isChecking
                            ? 'Memeriksa...'
                            : 'Saya Sudah Verifikasi',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSending ? null : _resendEmail,
                      icon: _isSending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isSending
                            ? 'Mengirim Email...'
                            : 'Kirim Ulang Email Verifikasi',
                      ),
                    ),
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _messageIsError
                            ? AppColors.error.withValues(alpha: 0.08)
                            : AppColors.secondary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _messageIsError
                              ? AppColors.error
                              : AppColors.secondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar dari Akun'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
