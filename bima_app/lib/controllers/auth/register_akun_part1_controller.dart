// Controller untuk langkah 1 pendaftaran akun (data diri dasar).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indonesia_regions/indonesia_regions.dart';

class RegisterAkunPart1Controller extends GetxController {
  final currentStep = 1;
  final totalSteps = 4;

  final namaLengkapController = TextEditingController();
  final nipController = TextEditingController();
  final selectedGender = Rxn<String>();
  final selectedAsalDaerah = Rxn<String>();

  final genderOptions = const ['Laki - laki', 'Perempuan'];

  /// Semua kabupaten/kota se-Indonesia (data BPS, offline, ~514 entri),
  /// digabung dari seluruh provinsi lalu diurutkan A-Z untuk dropdown
  /// "Asal Daerah". Dihitung sekali saja lewat `late final`.
  late final List<String> asalDaerahOptions = _buildAsalDaerahOptions();

  static List<String> _buildAsalDaerahOptions() {
    final names = <String>[
      for (final province in IndonesiaRegions.getProvinces())
        for (final regency in IndonesiaRegions.getRegencies(province.id)) regency.displayName,
    ];
    names.sort();
    return names;
  }

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
    super.onClose();
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
  }

  void selectAsalDaerah(String daerah) {
    selectedAsalDaerah.value = daerah;
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

    // Double check di FE mengikuti aturan backend: NIP hanya angka (tidak
    // boleh ada huruf/simbol) dan minimal 2 digit.
    if (!RegExp(r'^\d+$').hasMatch(nip)) {
      Get.snackbar(
        'NIP tidak valid',
        'NIP hanya boleh berisi angka, tanpa huruf atau simbol.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (nip.length < 2) {
      Get.snackbar(
        'NIP tidak valid',
        'NIP terlalu pendek, masukan NIP yang lengkap.',
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

    if (selectedAsalDaerah.value == null) {
      Get.snackbar(
        'Asal daerah wajib dipilih',
        'Pilih kota/kabupaten asal Anda.',
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
      // API menerima gender sebagai kode angka ('1' Laki-laki, '2' Perempuan)
      // — indeks di genderOptions kebetulan cocok (0->1, 1->2).
      'gender': (genderOptions.indexOf(selectedGender.value!) + 1).toString(),
      'asalDaerah': selectedAsalDaerah.value,
    };

    Get.toNamed('/register-kontak-jabatan', arguments: data);
  }
}
