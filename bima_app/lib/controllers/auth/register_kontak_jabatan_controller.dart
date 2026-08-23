// Controller untuk langkah pendaftaran yang mengumpulkan data kontak
// dan jabatan calon anggota.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterKontakJabatanController extends GetxController {
  final currentStep = 2;
  final totalSteps = 4;

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final selectedJabatan = Rxn<String>();

  final jabatanOptions = const ['Anggota', 'Danru', 'Chief'];

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
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void selectJabatan(String jabatan) {
    selectedJabatan.value = jabatan;
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
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    // Double check di FE mengikuti aturan backend: format email harus valid.
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      Get.snackbar(
        'Email tidak valid',
        'Masukan alamat email yang benar.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (phone.isEmpty) {
      Get.snackbar(
        'Nomor HP wajib diisi',
        'Masukan nomor HP yang terhubung dengan WhatsApp.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Double check di FE mengikuti aturan backend: nomor HP hanya angka,
    // panjang 8-15 digit (lihat skenario test nomor HP di dokumentasi API).
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      Get.snackbar(
        'Nomor HP tidak valid',
        'Nomor HP hanya boleh berisi angka, tanpa huruf atau simbol.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (phone.length < 8 || phone.length > 15) {
      Get.snackbar(
        'Nomor HP tidak valid',
        'Nomor HP harus terdiri dari 8-15 digit.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedJabatan.value == null) {
      Get.snackbar(
        'Jabatan belum dipilih',
        'Pilih jabatan Anda untuk melanjutkan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final data = {
      ..._previousData,
      'email': email,
      'phone': phone,
      // API menerima jabatan huruf kecil ('anggota'/'danru'/'chief').
      'jabatan': selectedJabatan.value!.toLowerCase(),
    };

    Get.toNamed('/register-akun-part3', arguments: data);
  }
}
