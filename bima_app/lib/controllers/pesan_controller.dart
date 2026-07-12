import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PesanItem {
  final String sender;
  final String time;
  final String preview;
  final String fullBody;
  final bool isPanic;
  final bool isRead;

  PesanItem({
    required this.sender,
    required this.time,
    required this.preview,
    String? fullBody,
    this.isPanic = false,
    this.isRead = false,
  }) : fullBody = fullBody ?? preview;
}

class PesanController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final messages = <PesanItem>[
    PesanItem(
      sender: 'Nama Satpam',
      time: 'Hari ini · 02:31',
      preview: 'menekan tombol panik. Segera periksa lokasinya.',
      isPanic: true,
    ),
    PesanItem(
      sender: 'Nama Mitra',
      time: 'Hari ini · 19:31',
      preview:
          'Radius check-in di Pos Utama diperluas dari 50m menjadi 80m mulai shift ini untuk mengakomodasi kondisi lapangan.',
    ),
    PesanItem(
      sender: 'Nama Mitra',
      time: 'Hari ini · 19:31',
      preview:
          'Diharapkan kepada seluruh personel untuk memperhatikan jadwal patroli pada shift ini dengan saksama. Pelaksanaan ronda wajib dilakukan secara rutin setiap 2 jam guna meminimalisir risiko keamanan...',
      fullBody:
          'Diharapkan kepada seluruh personel untuk memperhatikan jadwal patroli pada shift ini dengan saksama. Pelaksanaan ronda wajib dilakukan secara rutin setiap 2 jam guna meminimalisir risiko keamanan, dan Anda diwajibkan untuk langsung melaporkan kondisi lingkungan terkini melalui aplikasi sistem. Sebelum memasuki pukul 23:00, pastikan kepastian status semua pintu dalam keadaan terkunci rapat tanpa ada yang terlewat.',
    ),
    PesanItem(
      sender: 'Nama Mitra',
      time: 'Hari ini · 19:31',
      preview: 'Isi Pesan',
      isRead: true,
    ),
  ].obs;

  int get unreadCount => messages.where((m) => !m.isRead).length;

  void notAvailable() {
    Get.snackbar(
      'Segera Hadir',
      'Fitur ini belum tersedia.',
      backgroundColor: primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openMessage(PesanItem item) {
    Get.dialog(
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.sender,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                item.fullBody,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
