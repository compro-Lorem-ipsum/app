// Controller untuk langkah 3 pendaftaran akun: upload PAS foto.
// Foto dipilih langsung dari file (JPG/PNG) memakai file_picker,
// bukan dari kamera.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterAkunUploadFotoController extends GetxController {
  final currentStep = 3;
  final totalSteps = 4;

  final hasPhoto = false.obs;
  final photoPath = ''.obs;

  Map<String, dynamic> _previousData = {};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _previousData = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }
  }

  Future<void> handleUploadTap() async {
    if (hasPhoto.value) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      // Sesuai kontrak backend: jpg/png/webp diterima (201), format lain
      // ditolak (400) — lihat catatan skenario test avatar di
      // register_akun_part4_controller.dart.
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final path = result?.files.single.path;
    if (path != null) {
      photoPath.value = path;
      hasPhoto.value = true;
    }
  }

  void handleHapus() {
    hasPhoto.value = false;
    photoPath.value = '';
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
    if (!hasPhoto.value) {
      Get.snackbar(
        'Foto belum diunggah',
        'Unggah PAS foto Anda untuk melanjutkan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final data = {
      ..._previousData,
      'photoPath': photoPath.value,
    };

    Get.toNamed('/register-akun-part4', arguments: data);
  }
}
