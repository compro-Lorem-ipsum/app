// Controller untuk langkah 3 pendaftaran akun: upload PAS foto.
// Foto bisa diambil langsung dari kamera (image_picker) atau dipilih dari
// file JPG/PNG/WebP (file_picker) — kamera disediakan karena sebagian HP
// tidak bisa memilih/mengunggah file.
//
// Foto ini baru benar-benar diunggah & dicek deteksi wajahnya oleh
// backend saat submit akhir di step 4 (lihat RegisterAkunPart4Controller).
// Kalau backend menolak karena wajah tidak terdeteksi (atau error lain
// terkait foto), part4 akan Get.back() ke sini dan mengisi [uploadError]
// lewat [setUploadError] supaya keterangannya tampil inline di halaman
// ini — sesuai desain Figma node 44:1055 — bukan lewat notifikasi di
// halaman password.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RegisterAkunUploadFotoController extends GetxController {
  final currentStep = 3;
  final totalSteps = 4;

  static const _maxPhotoBytes = 2 * 1024 * 1024;

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

  /// Tombol unggah menampilkan pilihan: ambil dari kamera atau upload file.
  Future<void> handleUploadTap() async {
    Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari kamera'),
              onTap: () {
                Get.back();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload dari file'),
              onTap: () {
                Get.back();
                _pickFromFile();
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Future<void> _pickFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      // Sesuai kontrak backend: jpg/png/webp diterima (201), format lain
      // ditolak (400) — lihat catatan skenario test avatar di
      // register_akun_part4_controller.dart.
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final path = result?.files.single.path;
    if (path != null) await _acceptPhoto(path);
  }

  Future<void> _pickFromCamera() async {
    try {
      // Dikompres & diperkecil saat dipotret supaya hampir selalu < 2 MB;
      // ukurannya tetap diverifikasi di _acceptPhoto.
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (photo == null) return;
      await _acceptPhoto(photo.path);
    } catch (e) {
      uploadError.value = 'Kamera tidak dapat dibuka. Periksa izin kamera lalu coba lagi.';
    }
  }

  /// Terima foto hanya kalau <= [_maxPhotoBytes]; kalau lebih, tampilkan
  /// peringatan dan biarkan foto sebelumnya (kalau ada) tetap dipakai.
  Future<void> _acceptPhoto(String path) async {
    final size = await File(path).length();
    if (size > _maxPhotoBytes) {
      Get.snackbar(
        'Ukuran foto terlalu besar',
        'Ukuran foto maksimal 2 MB. Foto Anda ${(size / (1024 * 1024)).toStringAsFixed(1)} MB.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      uploadError.value = 'Ukuran foto maksimal 2 MB. Pilih atau ambil foto lain.';
      return;
    }
    photoPath.value = path;
    hasPhoto.value = true;
    uploadError.value = '';
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
