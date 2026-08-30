// Controller untuk halaman Profil Saya (data diri satpam yang login).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

class ProfileSayaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final documentsComplete = false.obs;

  // TODO: isi dari GET profil satpam begitu endpoint kontak darurat siap.
  // Selama belum ada data (hasil GET kosong/null), tampilan hanya
  // menunjukkan tombol "Tambah Kontak Darurat".
  final kontakDarurat = Rxn<Map<String, String>>();

  void openDocuments() {
    Get.toNamed('/unggah-berkas');
  }

  Future<void> openKontakDarurat({Map<String, String>? existing}) async {
    final result = await Get.toNamed('/tambah-kontak-darurat', arguments: existing);
    if (result is Map<String, String>) {
      kontakDarurat.value = result.isEmpty ? null : result;
    }
  }

  Future<void> logout() async {
    await AuthService().logout();
    Get.offAllNamed('/login');
  }
}
