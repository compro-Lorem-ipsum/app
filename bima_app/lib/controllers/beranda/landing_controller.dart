// Controller kecil untuk halaman Beranda: hanya menyimpan status "sedang
// bertugas atau tidak" (dibaca dari TrackingService, lihat
// services/tracking_service.dart) supaya tombol Check-in di kartu 'Status
// Hari ini' bisa otomatis berubah jadi Check-out setelah check-in berhasil.

import 'package:get/get.dart';

import '../../services/tracking_service.dart';

class LandingController extends GetxController {
  final isOnDuty = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    isOnDuty.value = await TrackingService().isOnDuty();
  }
}
