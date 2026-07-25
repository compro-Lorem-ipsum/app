// Controller untuk halaman Dokumen Repositori (daftar dokumen).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DokumenItem {
  final String title;
  final String size;
  final String date;

  DokumenItem({required this.title, required this.size, required this.date});
}

class RepDoksController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final dokumen = <DokumenItem>[
    DokumenItem(title: 'SOP Menangani Kebakaran Men...', size: '1.1 MB', date: '31 Des 2026'),
    DokumenItem(title: 'Prosedur CPR', size: '3.5 MB', date: '21 Jan 2026'),
    DokumenItem(title: 'Peraturan Perusahaan', size: '2.1 MB', date: '21 Jan 2026'),
  ].obs;

  void notAvailable() {
    Get.snackbar(
      'Segera Hadir',
      'Fitur ini belum tersedia.',
      backgroundColor: primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
