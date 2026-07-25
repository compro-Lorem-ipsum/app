// Tampilan langkah pendaftaran untuk data kontak & jabatan.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_kontak_jabatan_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/option_selector.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterKontakJabatanView extends GetView<RegisterKontakJabatanController> {
  const RegisterKontakJabatanView({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      header: WizardHeader(
        currentStep: controller.currentStep,
        totalSteps: controller.totalSteps,
        stepLabel: 'Kontak & Jabatan',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kontak & Jabatan', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
          const SizedBox(height: 8),
          Text(
            'Email, nomor HP, dan jabatan Anda',
            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Email',
            controller: controller.emailController,
            hint: 'nama@gmail.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Nomor HP',
            controller: controller.phoneController,
            hint: 'Masukan No HP Anda',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan Nomor HP Terhubung dengan WhatsApp',
            style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled),
          ),
          const SizedBox(height: 24),
          Text('Jabatan', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 10),
          Obx(() => OptionSelector(
                options: controller.jabatanOptions,
                selected: controller.selectedJabatan.value,
                onSelect: controller.selectJabatan,
              )),
        ],
      ),
      buttonLabel: 'Lanjutkan',
      onButtonPressed: controller.handleLanjutkan,
    );
  }
}
