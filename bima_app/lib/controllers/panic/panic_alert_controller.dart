// Controller untuk halaman Panic Alert.
// Mengurus status GPS (dengan fallback ke lokasi terakhir bila timeout),
// gesture geser-untuk-konfirmasi, serta overlay animasi 'Terkirim'
// setelah panic alert berhasil dikirim.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/confirm_dialog.dart';

class PanicAlertController extends GetxController {
  var isGpsActive = false.obs;
  var isSending = false.obs;
  var latitude = ''.obs;
  var longitude = ''.obs;

  final String namaSatpam = 'Nama Satpam';
  final String nip = 'NIP 123xxx';
  final String lokasiPos = 'Lokasi Pos - Nama Mitra';

  @override
  void onInit() {
    super.onInit();
    _checkGpsStatus();
  }

  Future<void> _checkGpsStatus() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        isGpsActive.value = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isGpsActive.value = false;
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        debugPrint('PanicAlertController: getCurrentPosition timed out, falling back to last known position');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        isGpsActive.value = false;
        return;
      }

      latitude.value = position.latitude.toStringAsFixed(6);
      longitude.value = position.longitude.toStringAsFixed(6);
      isGpsActive.value = true;
    } catch (e) {
      debugPrint('PanicAlertController: failed to resolve GPS status: $e');
      isGpsActive.value = false;
    }
  }

  String get koordinatText {
    if (latitude.value.isEmpty || longitude.value.isEmpty) return 'longitude,  latitude';
    return '$longitude,  $latitude';
  }

  /// Shows the "Konfirmasi Panic Alert" dialog (slide-to-confirm gesture
  /// completed). Returns true if the user tapped Kirim and the alert was
  /// sent, false if they cancelled/dismissed so the slide gesture resets.
  Future<bool> confirmAndSend() async {
    if (!isGpsActive.value || isSending.value) return false;

    final confirmed = await showConfirmDialog(
      title: 'Konfirmasi Panic Alert',
      message: "Sistem akan otomatis mengirimkan lokasi Anda ke pusat komando, atau tekan 'Batal' untuk membatalkan.",
      confirmLabel: 'Kirim',
      countdownSeconds: 3,
      accentColor: const Color(0xFFA80808),
    );

    if (confirmed != true) return false;

    await sendPanicAlert();
    return true;
  }

  Future<void> sendPanicAlert() async {
    if (!isGpsActive.value || isSending.value) return;

    isSending.value = true;
    // TODO: integrate real panic alert API call once backend endpoint is available.
    await Future.delayed(const Duration(milliseconds: 300));
    isSending.value = false;

    showSentDialog();
  }

  void showSentDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: _buildSentOverlay(),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
    );
  }

  Widget _buildSentOverlay() {
    return SizedBox.expand(
      child: Container(
        color: const Color(0xB3A70202),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                    );
                  },
                  child: SizedBox(
                    width: 157,
                    height: 157,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 157,
                          height: 157,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        Container(
                          width: 129,
                          height: 129,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        Container(
                          width: 95,
                          height: 95,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                        SvgPicture.asset(
                          'assets/icons/check_bold.svg',
                          width: 53,
                          height: 53,
                          colorFilter: const ColorFilter.mode(Color(0xFFA80808), BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Panik Alert Terkirim',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 30, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin telah menerima notifikasi darurat Anda beserta lokasi. Tetap di tempat aman.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 133,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: finishAndClose,
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFFA70202)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void finishAndClose() {
    Get.close(2);
  }

  void handleBack() {
    Get.back();
  }
}
