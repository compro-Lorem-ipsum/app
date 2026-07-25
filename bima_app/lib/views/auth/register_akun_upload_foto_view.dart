// Tampilan langkah 3 pendaftaran akun: upload PAS foto dari file
// (bukan kamera), dengan preview foto yang sudah dipilih.

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
          Obx(() => Center(
                child: GestureDetector(
                  onTap: controller.handleUploadTap,
                  child: Container(
                    width: 224,
                    height: 279,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x338D8787),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.disabled, style: BorderStyle.solid),
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
              )),
          const SizedBox(height: 16),
          Text(
            'Pakai pakaian formal, wajah terlihat jelas,\ntanpa masker & kacamata gelap',
            textAlign: TextAlign.center,
            style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled),
          ),
          const SizedBox(height: 20),
          Obx(() => controller.hasPhoto.value
              ? Center(
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
              : const SizedBox(height: 38)),
        ],
      ),
      buttonLabel: 'Lanjutkan',
      onButtonPressed: controller.handleLanjutkan,
    );
  }
}
