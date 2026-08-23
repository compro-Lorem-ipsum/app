// Controller untuk halaman Profil Saya (data diri satpam yang login).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

class ProfileSayaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final documentsComplete = false.obs;

  void openDocuments() {
    Get.toNamed('/unggah-berkas');
  }

  Future<void> logout() async {
    await AuthService().clearSession();
    Get.offAllNamed('/login');
  }
}
