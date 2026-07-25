// Controller untuk halaman Masuk (Login).
// Menyimpan input NIP/email & password, toggle show/hide password,
// checkbox 'Ingat Saya', dan navigasi setelah submit (belum ada
// pemanggilan API autentikasi sungguhan).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final nipController = TextEditingController();
  final passwordController = TextEditingController();
  final rememberMe = false.obs;
  final obscurePassword = true.obs;

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

  // Placeholder auth: no real backend call yet, just wires the login → home flow.
  void handleMasuk() {
    Get.offAllNamed('/');
  }
}
