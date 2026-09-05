// Tampilan halaman Unggah Berkas (KTP/BPJS/NPWP): kartu progres,
// baris per dokumen dengan icon sesuai tipe file (JPG/PDF), dan tombol
// unggah dari file (bukan kamera).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/dokumen/unggah_berkas_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/card_container.dart';
import '../../widgets/primary_button.dart';

class UnggahBerkasView extends StatelessWidget {
  const UnggahBerkasView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnggahBerkasController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    Text(
                      'KTP, BPJS, dan NPWP · JPG atau PDF',
                      style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
                    ),
                    const SizedBox(height: 20),
                    Obx(() => _buildProgressCard(controller)),
                    const SizedBox(height: 16),
                    Obx(() => Column(
                          children: controller.slots
                              .map((slot) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildDocumentRow(controller, slot),
                                  ))
                              .toList(),
                        )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
              child: Obx(() => PrimaryButton(
                    label: controller.isComplete ? 'Simpan Berkas' : 'Unggah Berkas',
                    onPressed: controller.isComplete ? controller.submit : null,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: SvgPicture.asset('assets/icons/arrow_left.svg', width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Unggah Berkas',
            style: AppText.semiBold.copyWith(fontSize: 25, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(UnggahBerkasController controller) {
    final progress = controller.uploadedCount / controller.slots.length;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kelengkapan Berkas', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
              Text(
                '${controller.uploadedCount} / ${controller.slots.length} Terunggah',
                style: AppText.bold.copyWith(fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// `fileSize` cuma dikenal untuk file yang baru saja dipilih di sesi ini
  /// (backend tidak mengirim ukuran byte untuk dokumen lama) - jangan
  /// ditampilkan sama sekali kalau null, daripada muncul teks "null"
  /// literal. Label & warna ikut status validasi backend
  /// (VALID/PENDING/INVALID) — dokumen yang masih diproses atau ditolak
  /// tidak boleh terlihat sama seperti yang sudah berhasil.
  Widget _buildStatusRow(DocumentSlot slot) {
    final String label;
    final Color color;
    final String? icon;
    switch (slot.fileStatus) {
      case 'INVALID':
        label = 'Ditolak, unggah ulang';
        color = const Color(0xFFA70202);
        icon = null;
        break;
      case 'PENDING':
        label = 'Sedang diproses';
        color = AppColors.disabled;
        icon = 'assets/icons/clock_icon.svg';
        break;
      default:
        label = 'Berhasil diunggah';
        color = const Color(0xFF008236);
        icon = 'assets/icons/check_one.svg';
    }

    return Row(
      children: [
        if (slot.fileSize != null) Text('${slot.fileSize} · ', style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled)),
        if (icon != null) ...[
          SvgPicture.asset(icon, width: 12, height: 12),
          const SizedBox(width: 4),
        ],
        Text(label, style: AppText.medium.copyWith(fontSize: 10, color: color)),
      ],
    );
  }

  Widget _buildDocumentRow(UnggahBerkasController controller, DocumentSlot slot) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slot.title, style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: SvgPicture.asset(
                    slot.isPdf ? 'assets/icons/pdf_outline.svg' : 'assets/icons/id_card.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slot.uploaded
                      ? [
                          Text(slot.fileName ?? slot.title, style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
                          const SizedBox(height: 6),
                          _buildStatusRow(slot),
                        ]
                      : [
                          Text(slot.subtitle, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
                        ],
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final isProcessingThis = controller.processingKey.value == slot.key;
                if (isProcessingThis) {
                  return const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  );
                }
                final isBusy = controller.processingKey.value != null;
                if (!slot.uploaded) {
                  return GestureDetector(
                    onTap: isBusy ? null : () => controller.upload(slot),
                    child: Icon(Icons.cloud_upload_outlined, color: isBusy ? AppColors.disabled : AppColors.primary, size: 30),
                  );
                }
                return GestureDetector(
                  onTap: isBusy ? null : () => controller.remove(slot),
                  child: Opacity(
                    opacity: isBusy ? 0.4 : 1,
                    child: SvgPicture.asset('assets/icons/delete_circle.svg', width: 30, height: 30),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
