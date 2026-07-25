// Tampilan langkah 1 pendaftaran akun.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_part1_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/option_selector.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterAkunPart1View extends GetView<RegisterAkunPart1Controller> {
  const RegisterAkunPart1View({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      header: WizardHeader(
        currentStep: controller.currentStep,
        totalSteps: controller.totalSteps,
        stepLabel: 'Data Diri',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Diri Anda', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
          const SizedBox(height: 8),
          Text(
            'Informasi dasar untuk profil personel',
            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Nama Lengkap',
            controller: controller.namaLengkapController,
            hint: 'Masukan Nama Lengkap Anda',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'NIP',
            controller: controller.nipController,
            hint: 'Masukan NIP Anda',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Text('Jenis Kelamin', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 10),
          Obx(() => OptionSelector(
                options: controller.genderOptions,
                selected: controller.selectedGender.value,
                onSelect: controller.selectGender,
              )),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Asal Daerah',
            controller: controller.asalDaerahController,
            hint: 'Kota / Kabupaten Asal',
          ),
        ],
      ),
      buttonLabel: 'Lanjutkan',
      onButtonPressed: controller.handleLanjutkan,
    );
  }
}
