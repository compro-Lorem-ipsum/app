import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/bubble_success_screen.dart';

class LupaPasswordController extends GetxController {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

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

  void handleKirimOtp() {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'Email tidak valid',
        'Masukan alamat email yang benar.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.toNamed('/lupa-password-part2');
  }

  void handleOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  void handleKirimUlang() {
    Get.snackbar(
      'Kode OTP terkirim ulang',
      'Silakan cek kotak masuk / spam Anda.',
      backgroundColor: const Color(0xFF122C93),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void handleResetPassword() {
    final otp = otpControllers.map((c) => c.text).join();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (otp.length < 6) {
      Get.snackbar(
        'Kode OTP belum lengkap',
        'Masukan 6 digit kode OTP Anda.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      Get.snackbar(
        'Password tidak valid',
        'Masukan password minimal 6 karakter.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (confirmPassword != newPassword) {
      Get.snackbar(
        'Konfirmasi password tidak sesuai',
        'Pastikan konfirmasi password sama dengan password.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.off(() => BubbleSuccessScreen(
          title: 'Atur Ulang Sandi Berhasil',
          subtitle: 'Kata sandi akun Anda telah diperbarui. Silakan masuk kembali menggunakan kata sandi yang baru.',
          buttonLabel: 'Kembali ke Login',
          onButtonPressed: () => Get.offAllNamed('/login'),
        ));
  }
}
