
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../auth/verify_email_page.dart';
import '../customer/customer_home_page.dart';
import '../jastiper/jastiper_home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final UserService _userService = UserService();

  String? _creatingUid;
  Future<void>? _ensureFuture;

  Future<void> _ensureUser(User user) {
    if (_creatingUid != user.uid || _ensureFuture == null) {
      _creatingUid = user.uid;

      _ensureFuture = _userService.ensureUserDocument(
        uid: user.uid,
        nama: user.displayName ?? '',
        email: user.email ?? '',
      );
    }

    return _ensureFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges memantau perubahan status emailVerified
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }

        if (authSnapshot.hasError) {
          return _ErrorPage(
            message: 'Gagal memeriksa akun: ${authSnapshot.error}',
          );
        }

        final firebaseUser = authSnapshot.data;

        // Belum login
        if (firebaseUser == null) {
          _creatingUid = null;
          _ensureFuture = null;

          return const LoginPage();
        }

        // Email belum diverifikasi
        if (!firebaseUser.emailVerified) {
          return const VerifyEmailPage();
        }

        // Email sudah diverifikasi, lanjut memuat profil
        return StreamBuilder<UserModel?>(
          stream: _userService.userStream(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return _ErrorPage(
                message: 'Gagal memuat profil: ${userSnapshot.error}',
              );
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }

            final user = userSnapshot.data;

            // Jika profil belum tersedia, buat dokumen pengguna
            if (user == null) {
              return FutureBuilder<void>(
                future: _ensureUser(firebaseUser),
                builder: (context, ensureSnapshot) {
                  if (ensureSnapshot.hasError) {
                    return _ErrorPage(
                      message:
                          'Gagal membuat profil: ${ensureSnapshot.error}',
                    );
                  }

                  return const _LoadingPage();
                },
              );
            }

            // Arahkan berdasarkan mode terakhir yang dipilih
            if (user.activeMode == 'jastiper') {
              return JastiperHomePage(user: user);
            }

            return CustomerHomePage(user: user);
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String message;

  const _ErrorPage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
