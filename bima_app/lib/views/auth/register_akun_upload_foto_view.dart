// Tampilan langkah 3 pendaftaran akun: upload PAS foto dari file
// (bukan kamera), dengan preview foto yang sudah dipilih.
//
// Kotak foto selalu berborder putus-putus (dashed) sesuai desain Figma:
//
// - Normal (node 44:1035): border abu-abu, keterangan abu-abu di bawah
//   foto, tombol kecil "Hapus" kalau sudah ada foto, tombol bawah
//   "Lanjutkan" biru solid.
// - Error (node 44:1055): border merah, keterangan error merah di bawah
//   foto (foto yang di-preview TETAP foto yang tadi diunggah user), tombol
//   kecil disembunyikan, dan tombol bawah berubah menjadi "Upload Ulang"
//   outline merah yang membuka file picker lagi. Memilih foto baru
//   otomatis menghapus errornya dan mengembalikan tampilan normal.
//
// Errornya diisi dari step 4 lewat RegisterAkunUploadFotoController
// .setUploadError setelah backend menolak foto (wajah tidak terdeteksi /
// gagal unggah) saat user menekan "Daftar Sekarang" di halaman password —
// part4 Get.back() ke sini, bukan menampilkan notifikasi di halaman itu.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_upload_foto_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterAkunUploadFotoView extends GetView<RegisterAkunUploadFotoController> {
  const RegisterAkunUploadFotoView({super.key});

  // Warna merah dari Figma: --red-primary untuk border/garis tepi,
  // --red-fond untuk teks.
  static const redPrimaryColor = Color(0xFFA70202);
  static const redFontColor = Color(0xFFC10007);

  @override
  Widget build(BuildContext context) {
    // Seluruh scaffold reaktif terhadap uploadError karena tombol bawah
    // (label, gaya, aksi) ikut berubah saat error — bukan hanya kontennya.
    return Obx(() {
      final hasError = controller.uploadError.value.isNotEmpty;
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
            Center(
              child: GestureDetector(
                onTap: controller.handleUploadTap,
                child: SizedBox(
                  width: 224,
                  height: 279,
                  child: CustomPaint(
                    painter: _DashedBorderPainter(color: hasError ? redPrimaryColor : AppColors.disabled, radius: 10),
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
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                // Lebar teks keterangan di Figma (238) supaya pembungkusan
                // barisnya sama dengan desain.
                width: 238,
                child: hasError
                    ? Text(
                        controller.uploadError.value,
                        textAlign: TextAlign.center,
                        style: AppText.regular.copyWith(fontSize: 10, color: redFontColor),
                      )
                    : Text(
                        'Pakai pakaian formal, wajah terlihat jelas,\ntanpa masker & kacamata gelap',
                        textAlign: TextAlign.center,
                        style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Tombol kecil "Hapus" hanya pada kondisi normal & sudah ada
            // foto. Saat error tidak ada tombol kecil (Figma 44:1055) —
            // aksinya pindah ke tombol bawah "Upload Ulang".
            if (controller.hasPhoto.value && !hasError)
              Center(
                child: SizedBox(
                  width: 228,
                  height: 38,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: redPrimaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: controller.handleHapus,
                    child: Text(
                      'Hapus',
                      style: AppText.semiBold.copyWith(fontSize: 12, color: redFontColor),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 38),
          ],
        ),
        buttonLabel: hasError ? 'Upload Ulang' : 'Lanjutkan',
        onButtonPressed: hasError ? controller.handleUploadTap : controller.handleLanjutkan,
        buttonOutlined: hasError,
        buttonColor: hasError ? redPrimaryColor : null,
        buttonTextColor: hasError ? redFontColor : null,
      );
    });
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
