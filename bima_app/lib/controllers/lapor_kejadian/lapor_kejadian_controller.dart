// Controller untuk halaman Laporan Kejadian (lapor insiden di lokasi).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/primary_button.dart';

class LaporKejadianController extends GetxController {
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;
  final gpsActive = false.obs;

  final photos = List<String>.filled(4, '').obs;
  final descriptionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    getGPS();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> getGPS() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = pos.latitude;
      longitude.value = pos.longitude;
      gpsActive.value = true;
    } catch (_) {}
  }

  Future<void> goToCamera(int index) async {
    final result = await Get.toNamed('/take-photo-patroli');

    if (result != null && result is String) {
      photos[index] = result;
      photos.refresh();
    }
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void submitReport() {
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Deskripsi wajib diisi',
        'Jelaskan kejadian yang sedang terjadi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Laporan Berhasil',
                textAlign: TextAlign.center,
                style: AppText.bold.copyWith(fontSize: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Laporan Berhasil Dikirim',
                textAlign: TextAlign.center,
                style: AppText.regular.copyWith(fontSize: 13, color: AppColors.disabled),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: 'Selesai',
                  onPressed: () {
                    Get.back();
                    if (Get.key.currentState?.canPop() ?? false) {
                      Get.back();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
