// Controller untuk langkah 3 pendaftaran akun: upload PAS foto.
// Foto dipilih langsung dari file (JPG/PNG) memakai file_picker,
// bukan dari kamera.
//
// Foto ini baru benar-benar diunggah & dicek deteksi wajahnya oleh
// backend saat submit akhir di step 4 (lihat RegisterAkunPart4Controller).
// Kalau backend menolak karena wajah tidak terdeteksi (atau error lain
// terkait foto), part4 akan Get.back() ke sini dan mengisi [uploadError]
// lewat [setUploadError] supaya keterangannya tampil inline di halaman
// ini — sesuai desain Figma node 44:1055 — bukan lewat notifikasi di
// halaman password.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterAkunUploadFotoController extends GetxController {
  final currentStep = 3;
  final totalSteps = 4;

  final hasPhoto = false.obs;
  final photoPath = ''.obs;
  final uploadError = ''.obs;

  Map<String, dynamic> _previousData = {};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _previousData = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }
  }

  Future<void> handleUploadTap() async {
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
      uploadError.value = '';
    }
  }

  void handleHapus() {
    hasPhoto.value = false;
    photoPath.value = '';
    uploadError.value = '';
  }

  /// Dipanggil dari RegisterAkunPart4Controller kalau backend menolak
  /// foto saat submit (wajah tidak terdeteksi / error lain terkait foto).
  void setUploadError(String message) {
    uploadError.value = message;
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
