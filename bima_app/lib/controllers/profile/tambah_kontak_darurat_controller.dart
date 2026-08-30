// Controller untuk halaman tambah/ubah kontak darurat pada Profil Saya.
// Mode ubah aktif kalau halaman dibuka dengan `arguments` berisi data
// kontak darurat yang sudah ada (lihat ProfileSayaController.openKontakDarurat).
//
// Hasil disimpan lewat `Get.back(result: ...)`: Map berisi data kalau
// disimpan, Map kosong kalau dihapus, atau null kalau dibatalkan — supaya
// ProfileSayaController tahu persis apa yang harus dilakukan ke state-nya.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TambahKontakDaruratController extends GetxController {
  static const hubunganOptions = ['Orang Tua', 'Istri/Suami', 'Anak', 'Saudara'];

  final namaController = TextEditingController();
  final nomorHpController = TextEditingController();
  final selectedHubungan = Rxn<String>();
  final isDropdownOpen = false.obs;

  bool isEdit = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      isEdit = true;
      selectedHubungan.value = args['hubungan'] as String?;
      namaController.text = (args['nama'] as String?) ?? '';
      nomorHpController.text = (args['nomorHp'] as String?) ?? '';
    }
  }

  @override
  void onClose() {
    namaController.dispose();
    nomorHpController.dispose();
    super.onClose();
  }

  void toggleDropdown() => isDropdownOpen.value = !isDropdownOpen.value;

  void selectHubungan(String? value) {
    selectedHubungan.value = value;
    isDropdownOpen.value = false;
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void handleSimpan() {
    final nama = namaController.text.trim();
    final nomorHp = nomorHpController.text.trim();

    if (selectedHubungan.value == null) {
      _showError('Status/Hubungan belum dipilih', 'Pilih status/hubungan kontak darurat Anda.');
      return;
    }
    if (nama.isEmpty) {
      _showError('Nama wajib diisi', 'Masukan nama kontak darurat.');
      return;
    }
    if (nomorHp.isEmpty) {
      _showError('Nomor HP wajib diisi', 'Masukan nomor HP kontak darurat.');
      return;
    }

    Get.back(result: {
      'hubungan': selectedHubungan.value!,
      'nama': nama,
      'nomorHp': nomorHp,
    });
  }

  void handleHapus() {
    Get.back(result: const <String, String>{});
  }
}
