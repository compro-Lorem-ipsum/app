// Controller untuk langkah 1 pendaftaran akun (data diri dasar).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterAkunPart1Controller extends GetxController {
  final currentStep = 1;
  final totalSteps = 4;

  final namaLengkapController = TextEditingController();
  final nipController = TextEditingController();
  final asalDaerahController = TextEditingController();
  final selectedGender = Rxn<String>();

  final genderOptions = const ['Laki - laki', 'Perempuan'];

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
    namaLengkapController.dispose();
    nipController.dispose();
    asalDaerahController.dispose();
    super.onClose();
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
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
    final namaLengkap = namaLengkapController.text.trim();
    final nip = nipController.text.trim();
    final asalDaerah = asalDaerahController.text.trim();

    if (namaLengkap.isEmpty) {
      Get.snackbar(
        'Nama lengkap wajib diisi',
        'Masukan nama lengkap Anda.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (nip.isEmpty) {
      Get.snackbar(
        'NIP wajib diisi',
        'Masukan NIP Anda.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedGender.value == null) {
      Get.snackbar(
        'Jenis kelamin belum dipilih',
        'Pilih jenis kelamin Anda untuk melanjutkan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (asalDaerah.isEmpty) {
      Get.snackbar(
        'Asal daerah wajib diisi',
        'Masukan kota/kabupaten asal Anda.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final data = {
      ..._previousData,
      'namaLengkap': namaLengkap,
      'nip': nip,
      'gender': selectedGender.value,
      'asalDaerah': asalDaerah,
    };

    Get.toNamed('/register-kontak-jabatan', arguments: data);
  }
}
