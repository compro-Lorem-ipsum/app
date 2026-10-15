// Controller untuk halaman Masuk (Login).
// Memvalidasi input NIP/email & password, memanggil POST /auth/login, lalu
// menyimpan sesi (access token, refresh token, data user) lewat
// AuthService sebelum masuk ke halaman utama.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/error_mapper.dart';
import '../../services/fcm_service.dart';
import '../../services/panic_alert_polling_service.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class LoginController extends GetxController {
  final nipController = TextEditingController();
  final passwordController = TextEditingController();
  final rememberMe = false.obs;
  final obscurePassword = true.obs;
  final isSubmitting = false.obs;

  @override
  void onClose() {
    nipController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleRememberMe() => rememberMe.value = !rememberMe.value;

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;

  void handleLupaPassword() {
    Get.toNamed('/lupa-password-part1');
  }

  void handleDaftar() {
    Get.toNamed('/register-akun-part1');
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Backend membungkus error sebagai `{"error": {"code": ..., "message": ...}}`
  /// (lihat ACCOUNT_PENDING). `code` dipakai untuk menerjemahkan error yang
  /// pesan mentahnya kurang jelas buat pengguna; `statusCode` sebagai
  /// fallback kalau code tidak dikenali.
  void _showLoginError(int? statusCode, dynamic body) {
    final err = ErrorMapper.parse(body, statusCode: statusCode);

    switch (err.code) {
      case 'ACCOUNT_PENDING':
        _showError('Akun Menunggu Persetujuan', err.message);
        return;
      case 'ACCOUNT_REJECTED':
        _showError('Pendaftaran Ditolak', err.message);
        return;
      case 'ACCOUNT_INACTIVE':
        _showError('Akun Tidak Aktif', err.message);
        return;
      case 'INVALID_CREDENTIALS':
        _showError('NIP/Email atau Password Salah', err.message);
        return;
      case 'VALIDATION_ERROR':
        _showError('Data Tidak Valid', err.message);
        return;
      case 'FORBIDDEN':
        _showError('Akses Ditolak', err.message);
        return;
    }

    switch (statusCode) {
      case 401:
        _showError('NIP/Email atau Password Salah', err.message);
        return;
      case 422:
        _showError('Data Tidak Valid', err.message);
        return;
      case 403:
        _showError('Akses Ditolak', err.message);
        return;
      default:
        _showError('Masuk Gagal', err.message);
    }
  }

  Future<void> handleMasuk() async {
    if (isSubmitting.value) return;

    final identifier = nipController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty) {
      _showError('NIP/Email Wajib Diisi', 'Masukan NIP atau email Anda.');
      return;
    }

    if (password.isEmpty) {
      _showError('Password Wajib Diisi', 'Masukan password Anda.');
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await GetConnect().post(
        '$BASE_API_URL/auth/login',
        {'identifier': identifier, 'password': password},
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body;
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;

      if (ok) {
        final data = body is Map ? body['data'] as Map<String, dynamic>? : null;
        final user = data?['user'];
        if (data == null || user is! Map) {
          _showError('Masuk Gagal', 'Respons server tidak sesuai, coba lagi.');
          return;
        }

        // Lapisan pertahanan tambahan di klien: backend sudah menolak akun
        // 'pending' lewat error.code ACCOUNT_PENDING (lihat
        // _showLoginError), tapi status non-aktif LAIN (mis. disuspend/
        // dinonaktifkan admin) belum tentu ditolak di endpoint /auth/login
        // itu sendiri - field `status` di sini yang jadi penentu terakhir
        // sebelum sesi disimpan.
        final status = user['status']?.toString();
        if (status != null && status != 'active') {
          _showError('Akun Tidak Aktif', 'Akun Anda berstatus "$status" dan tidak dapat digunakan. Hubungi admin untuk informasi lebih lanjut.');
          return;
        }

        await AuthService().saveSession(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
          refreshExpiresAt: data['refresh_expires_at'] as String,
          user: Map<String, dynamic>.from(user),
          rememberMe: rememberMe.value,
        );

        // Mulai polling Panic Alert (lihat panic_alert_polling_service.dart)
        // — dihentikan lagi saat logout (ProfileSayaController.logout).
        await PanicAlertPollingService().start();

        // Daftarkan token FCM sekarang bahwa sudah ada access_token —
        // sebelum ini (satpam belum login) token hanya sempat terdaftar
        // lewat POST /satpam/register kalau ada (lihat fcm_service.dart).
        await FcmService().registerCurrentToken();

        Get.offAllNamed('/');
        return;
      }

      _showLoginError(response.statusCode, body);
    } catch (e) {
      debugPrint('LoginController: gagal masuk: $e');
      _showError('Masuk Gagal', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
    }
  }
}
