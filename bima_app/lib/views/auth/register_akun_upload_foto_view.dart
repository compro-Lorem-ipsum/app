// Tampilan langkah 3 pendaftaran akun: upload PAS foto dari file
// (bukan kamera), dengan preview foto yang sudah dipilih.
//
// Kotak foto selalu berborder putus-putus (dashed) sesuai desain Figma —
// abu-abu dalam kondisi normal (node 44:1035), merah + keterangan error
// inline di bawahnya kalau backend menolak foto ini karena wajah tidak
// terdeteksi atau error lain (node 44:1055). Errornya diisi dari step 4
// lewat RegisterAkunUploadFotoController.setUploadError setelah user
// menekan "Daftar Sekarang" di halaman password — bukan lewat notifikasi
// di halaman ini.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_upload_foto_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterAkunUploadFotoView extends GetView<RegisterAkunUploadFotoController> {
  const RegisterAkunUploadFotoView({super.key});

  static const redPrimaryColor = Color(0xFFA70202);
  static const redFontColor = Color(0xFFC10007);

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      header: WizardHeader(
        currentStep: controller.currentStep,
        totalSteps: controller.totalSteps,
        stepLabel: 'Upload PAS Foto',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload PAS Foto', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
          const SizedBox(height: 8),
          Text(
            'Untuk verifikasi identitas saat absensi wajah',
            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
          ),
          const SizedBox(height: 40),
          Obx(() {
            final hasError = controller.uploadError.value.isNotEmpty;
            return Center(
              child: GestureDetector(
                onTap: controller.handleUploadTap,
                child: SizedBox(
                  width: 224,
                  height: 279,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(color: hasError ? AppColors.danger : AppColors.disabled, radius: 10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x338D8787),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: controller.hasPhoto.value
                          ? Image.file(
                              File(controller.photoPath.value),
                              fit: BoxFit.cover,
                              width: 224,
                              height: 279,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person, size: 70, color: AppColors.disabled),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap untuk upload foto',
                                  textAlign: TextAlign.center,
                                  style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final error = controller.uploadError.value;
            if (error.isNotEmpty) {
              return Text(
                error,
                textAlign: TextAlign.center,
                style: AppText.regular.copyWith(fontSize: 10, color: redFontColor),
              );
            }
            return Text(
              'Pakai pakaian formal, wajah terlihat jelas,\ntanpa masker & kacamata gelap',
              textAlign: TextAlign.center,
              style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled),
            );
          }),
          const SizedBox(height: 20),
          Obx(() {
            if (!controller.hasPhoto.value) return const SizedBox(height: 38);
            final hasError = controller.uploadError.value.isNotEmpty;
            return Center(
              child: SizedBox(
                width: 228,
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: redPrimaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: hasError ? controller.handleUploadTap : controller.handleHapus,
                  child: Text(
                    hasError ? 'Upload Ulang' : 'Hapus',
                    style: AppText.semiBold.copyWith(fontSize: 12, color: redFontColor),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      buttonLabel: 'Lanjutkan',
      onButtonPressed: controller.handleLanjutkan,
    );
  }
}

/// Border putus-putus (dashed) rounded-rect untuk kotak foto — tidak ada
/// widget bawaan Flutter untuk ini dan tidak ada dependency dashed-border
/// di proyek, jadi digambar manual lewat CustomPainter.
class _DashedBorderPainter extends CustomPainter {
  static const _dashWidth = 6.0;
  static const _gapWidth = 4.0;

  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + _gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
