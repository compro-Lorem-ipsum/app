// Controller untuk alur Lupa Password: kirim OTP ke email (part 1) lewat
// POST /auth/forgot-password, lalu input OTP + password baru & konfirmasinya
// (part 2) lewat POST /auth/reset-password. LupaPasswordController hanya
// di-lazyPut sekali di route part1 (lihat main.dart) — part2 memakai
// instance yang sama sehingga emailController tetap terbawa antar layar.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../widgets/bubble_success_screen.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class LupaPasswordController extends GetxController {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isSendingOtp = false.obs;
  final isResetting = false.obs;

  void toggleNewPasswordVisibility() => obscureNewPassword.value = !obscureNewPassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

  @override
  void onClose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.onClose();
  }

  void handleClose() => Get.offAllNamed('/login');

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) Get.back();
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

  /// Panggil POST /auth/forgot-password. Backend selalu balas 200 dengan
  /// pesan generik ("if that email is registered...") supaya tidak bocorkan
  /// email mana yang terdaftar — jadi sukses di sini cuma berarti request-nya
  /// valid (format email benar), bukan konfirmasi email itu ada di sistem.
  Future<bool> _sendForgotPasswordRequest(String email) async {
    try {
      final response = await GetConnect().post(
        '$BASE_API_URL/auth/forgot-password',
        {'email': email},
        headers: {'Content-Type': 'application/json'},
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) return true;

      final body = response.body;
      final error = body is Map ? body['error'] : null;
      final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();
      _showError(
        response.statusCode == 422 ? 'Email Tidak Valid' : 'Gagal Mengirim OTP',
        rawMessage ?? 'Periksa kembali alamat email Anda.',
      );
      return false;
    } catch (e) {
      debugPrint('LupaPasswordController: gagal kirim forgot-password: $e');
      _showError('Gagal Mengirim OTP', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
      return false;
    }
  }

  Future<void> handleKirimOtp() async {
    if (isSendingOtp.value) return;

    final email = emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Email Tidak Valid', 'Masukan alamat email yang benar.');
      return;
    }

    isSendingOtp.value = true;
    try {
      final sent = await _sendForgotPasswordRequest(email);
      if (sent) Get.toNamed('/lupa-password-part2');
    } finally {
      isSendingOtp.value = false;
    }
  }

  void handleOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> handleKirimUlang() async {
    if (isSendingOtp.value) return;
    final email = emailController.text.trim();

    isSendingOtp.value = true;
    try {
      final sent = await _sendForgotPasswordRequest(email);
      if (sent) {
        Get.snackbar(
          'Kode OTP Terkirim Ulang',
          'Silakan cek kotak masuk / spam Anda.',
          backgroundColor: const Color(0xFF122C93),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> handleResetPassword() async {
    if (isResetting.value) return;

    final email = emailController.text.trim();
    final otp = otpControllers.map((c) => c.text).join();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (otp.length < 6) {
      _showError('Kode OTP Belum Lengkap', 'Masukan 6 digit kode OTP Anda.');
      return;
    }

    // API mewajibkan password baru minimal 8 karakter (lihat skenario
    // "password kurang dari 8 karakter" pada dokumentasi /auth/reset-password).
    if (newPassword.isEmpty || newPassword.length < 8) {
      _showError('Password Tidak Valid', 'Masukan password minimal 8 karakter.');
      return;
    }

    if (confirmPassword != newPassword) {
      _showError('Konfirmasi Password Tidak Sesuai', 'Pastikan konfirmasi password sama dengan password.');
      return;
    }

    isResetting.value = true;
    try {
      final response = await GetConnect().post(
        '$BASE_API_URL/auth/reset-password',
        {'email': email, 'code': otp, 'new_password': newPassword},
        headers: {'Content-Type': 'application/json'},
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        Get.off(() => BubbleSuccessScreen(
              title: 'Atur Ulang Sandi Berhasil',
              subtitle: 'Kata sandi akun Anda telah diperbarui. Silakan masuk kembali menggunakan kata sandi yang baru.',
              buttonLabel: 'Kembali ke Login',
              onButtonPressed: () => Get.offAllNamed('/login'),
            ));
        return;
      }

      _showResetPasswordError(response.statusCode, response.body);
    } catch (e) {
      debugPrint('LupaPasswordController: gagal reset password: $e');
      _showError('Gagal Mengatur Ulang Sandi', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isResetting.value = false;
    }
  }

  void _showResetPasswordError(int? statusCode, dynamic body) {
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code']?.toString() : null;
    final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();

    if (code == 'OTP_INVALID') {
      int? attemptsRemaining;
      if (error is Map) {
        final details = error['details'];
        if (details is Map && details['attempts_remaining'] is int) {
          attemptsRemaining = details['attempts_remaining'] as int;
        }
      }
      _showError(
        'Kode OTP Salah',
        attemptsRemaining != null
            ? '${rawMessage ?? 'Kode salah'} ($attemptsRemaining percobaan tersisa).'
            : rawMessage ?? 'Kode OTP salah.',
      );
      return;
    }

    switch (statusCode) {
      case 401:
        _showError('Kode OTP Tidak Valid', rawMessage ?? 'Kode OTP salah, sudah kedaluwarsa, atau email tidak sesuai.');
        return;
      case 422:
        _showError('Data Tidak Valid', rawMessage ?? 'Periksa kembali kode OTP dan password baru Anda.');
        return;
      default:
        _showError('Gagal Mengatur Ulang Sandi', rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.');
    }
  }
}
