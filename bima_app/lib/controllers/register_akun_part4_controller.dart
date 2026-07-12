import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterAkunPart4Controller extends GetxController {
  final currentStep = 4;
  final totalSteps = 4;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Map<String, dynamic> _previousData = {};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _previousData = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void handleClose() {
    Get.offAllNamed('/login');
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void handleLanjutkan() {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || password.length < 6) {
      Get.snackbar(
        'Password tidak valid',
        'Masukan password minimal 6 karakter.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (confirmPassword != password) {
      Get.snackbar(
        'Konfirmasi password tidak sesuai',
        'Pastikan konfirmasi password sama dengan password.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final data = {
      ..._previousData,
      'password': password,
    };

    Get.offNamedUntil('/register-akun-part5', (route) => route.settings.name == '/login', arguments: data);
  }
}
