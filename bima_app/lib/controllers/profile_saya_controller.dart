import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSayaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final documentsComplete = false.obs;

  void openDocuments() {
    Get.toNamed('/unggah-berkas');
  }

  void logout() {
    Get.offAllNamed('/login');
  }
}
