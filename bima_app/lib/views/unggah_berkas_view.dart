import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/unggah_berkas_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/card_container.dart';
import '../widgets/primary_button.dart';

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
                      'KTP, BPJS, dan NPWP · Foto',
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
          child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
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

  Widget _buildDocumentRow(UnggahBerkasController controller, DocumentSlot slot) {
    return CardContainer(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.badge_outlined, color: Colors.black54, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.title, style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Text(slot.subtitle, style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled)),
              ],
            ),
          ),
          if (!slot.uploaded)
            GestureDetector(
              onTap: () => controller.upload(slot),
              child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 30),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 6),
                Text('Berhasil diunggah', style: AppText.semiBold.copyWith(fontSize: 11, color: AppColors.success)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => controller.remove(slot),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
