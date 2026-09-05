// Tampilan halaman Check-in / Check-out.
// Berisi kartu identitas satpam, kartu lokasi & radius GPS, kartu
// Verifikasi Wajah (kamera live embedded dibungkus bentuk oval, lalu
// menampilkan hasil foto + badge 'Wajah Terverifikasi'), dan tombol
// aksi (Check-in/out sekarang & Batal).

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/absensi/absen_checkin_controller.dart';
import '../../widgets/card_container.dart';
import '../../widgets/map_preview.dart';

class AbsenCheckinView extends StatelessWidget {
  const AbsenCheckinView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const disabledColor = Color(0xFF8D8787);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);
  static const radiusBlueBg = Color(0xFFDBEAFE);
  static const radiusBlueText = Color(0xFF122C93);
  static const radiusRedBg = Color(0xFFFFE2E2);
  static const radiusRedText = Color(0xFFA70202);
  static const verifiedGreen = Color(0xFF008236);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AbsenCheckinController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 20),
              Obx(() => _buildSatpamCard(controller)),
              const SizedBox(height: 16),
              _buildLocationCard(controller),
              const SizedBox(height: 16),
              _buildVerifikasiCard(controller),
              const SizedBox(height: 16),
              _buildActionButtons(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbsenCheckinController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.offAllNamed('/'),
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        Text(
          controller.isCheckIn ? 'Check - in' : 'Check - out',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 25,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSatpamCard(AbsenCheckinController controller) {
    return CardContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(controller.displayNama, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
              const SizedBox(height: 4),
              Text('NIP ${controller.displayNip}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              const SizedBox(height: 2),
              Text(controller.displayClient, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(AbsenCheckinController controller) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('LOKASI', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: primaryColor)),
                  Text(' · OTOMATIS DARI GPS', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: greyText)),
                ],
              ),
              _buildRadiusPill(controller),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pos Utama - Nama Mitra',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Obx(() => MapPreview(
                latitude: controller.latitude.value,
                longitude: controller.longitude.value,
              )),
          const SizedBox(height: 6),
          Obx(() {
            if (controller.isLoadingLocation.value) {
              return const Text('Mencari lokasi...', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText));
            }
            final lat = controller.latitude.value.toStringAsFixed(6);
            final lng = controller.longitude.value.toStringAsFixed(6);
            final suffix = controller.isInRadius.value
                ? '${controller.distanceMeter.value.toStringAsFixed(0)} meter dari Pos'
                : 'Diluar Radius Pos';
            return Text(
              '$lat, $lng · $suffix',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRadiusPill(AbsenCheckinController controller) {
    return Obx(() {
      final inRadius = controller.isInRadius.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: inRadius ? radiusBlueBg : radiusRedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          inRadius ? 'Dalam Radius' : 'Diluar Radius',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 9,
            color: inRadius ? radiusBlueText : radiusRedText,
          ),
        ),
      );
    });
  }

  Widget _buildVerifikasiCard(AbsenCheckinController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verifikasi Wajah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: primaryColor)),
              Obx(() => controller.photoTaken.value
                  ? const Text(
                      'Wajah Terverifikasi',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 9, color: verifiedGreen),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 190,
              height: 230,
              child: Obx(() => ClipOval(
                    child: controller.photoTaken.value
                        ? Image.file(
                            File(controller.photoPath.value),
                            fit: BoxFit.cover,
                            width: 190,
                            height: 230,
                          )
                        : controller.isCameraInitialized.value
                            ? _buildLiveCameraPreview(controller.cameraController!)
                            : Container(
                                color: Colors.black12,
                                child: const Center(child: CircularProgressIndicator(color: primaryColor)),
                              ),
                  )),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Obx(() => Text(
                  controller.photoTaken.value ? 'Menunggu Konfirmasi Anda' : 'Posisikan wajah di dalam bingkai oval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontStyle: controller.photoTaken.value ? FontStyle.normal : FontStyle.italic,
                    fontSize: 12,
                    color: controller.photoTaken.value ? primaryColor : greyText,
                  ),
                )),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.photoTaken.value) return const SizedBox.shrink();
            final enabled = controller.isInRadius.value && !controller.isLoadingLocation.value && controller.isCameraInitialized.value;
            return SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? primaryColor : disabledColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: enabled ? controller.capturePhoto : null,
                child: const Text('Pindai Wajah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLiveCameraPreview(CameraController cameraController) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: cameraController.value.previewSize!.height,
        height: cameraController.value.previewSize!.width,
        child: CameraPreview(cameraController),
      ),
    );
  }

  Widget _buildActionButtons(AbsenCheckinController controller) {
    return Obx(() {
      if (!controller.photoTaken.value) return const SizedBox.shrink();
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: controller.isSubmitting.value ? null : controller.confirmAttendance,
              child: controller.isSubmitting.value
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      controller.isCheckIn ? 'Check in sekarang' : 'Check out sekarang',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: controller.retakePhoto,
              child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black)),
            ),
          ),
        ],
      );
    });
  }
}
