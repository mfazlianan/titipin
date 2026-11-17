
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Mengambil pengguna yang sedang login
  User? get currentUser => _auth.currentUser;

  // Mengamati perubahan data pengguna, termasuk status verifikasi email
  Stream<User?> get authStateChanges => _auth.userChanges();

  // ==========================================
  // REGISTRASI AKUN
  // ==========================================
  Future<UserCredential> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Registrasi gagal. Pengguna tidak ditemukan.');
    }

    // Menyimpan nama pengguna di Firebase Authentication
    await user.updateDisplayName(nama.trim());

    // Membuat profil pengguna di Firestore
    final userModel = UserModel(
      uid: user.uid,
      nama: nama.trim(),
      email: email.trim(),
    );

    await _userService.createUser(userModel);

    // Mengirim email verifikasi sungguhan melalui Firebase
    await user.sendEmailVerification();

    return credential;
  }

  // ==========================================
  // LOGIN AKUN
  // ==========================================
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _userService.ensureUserDocument(
        uid: user.uid,
        nama: user.displayName ?? '',
        email: user.email ?? email.trim(),
      );
    }

    return credential;
  }

  // ==========================================
  // MENGIRIM ULANG EMAIL VERIFIKASI
  // ==========================================
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw Exception('Pengguna tidak ditemukan.');
    }

    if (refreshedUser.emailVerified) {
      throw Exception('Email kamu sudah terverifikasi.');
    }

    await refreshedUser.sendEmailVerification();
  }

  // ==========================================
  // MEMERIKSA STATUS VERIFIKASI EMAIL
  // ==========================================
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    return refreshedUser?.emailVerified ?? false;
  }

  // ==========================================
  // MEMPERBARUI DATA PENGGUNA
  // ==========================================
  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    await user.reload();

    return _auth.currentUser;
  }

  // ==========================================
  // LOGOUT
  // ==========================================
  Future<void> logout() async {
    await _auth.signOut();
  }
}
