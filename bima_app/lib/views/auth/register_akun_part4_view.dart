// Tampilan langkah 4 pendaftaran akun: form password & konfirmasi
// password, masing-masing dengan tombol show/hide (ikon mata) seperti
// di halaman login.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_part4_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterAkunPart4View extends GetView<RegisterAkunPart4Controller> {
  const RegisterAkunPart4View({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => WizardScaffold(
      header: WizardHeader(
        currentStep: controller.currentStep,
        totalSteps: controller.totalSteps,
        stepLabel: 'Password',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buat password', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
          const SizedBox(height: 8),
          Text(
            'Password untuk masuk ke aplikasi mobile',
            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
          ),
          const SizedBox(height: 28),
          Obx(() => AppTextField(
                label: 'Password',
                controller: controller.passwordController,
                hint: 'Masukkan password',
                obscureText: controller.obscurePassword.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.disabled,
                    size: 20,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              )),
          const SizedBox(height: 20),
          Obx(() => AppTextField(
                label: 'Konfirmasi Ulang Password',
                controller: controller.confirmPasswordController,
                hint: 'konfirmasi ulang password',
                obscureText: controller.obscureConfirmPassword.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureConfirmPassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.disabled,
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              )),
        ],
      ),
      buttonLabel: controller.isSubmitting.value
          ? (controller.submitStatus.value.isEmpty ? 'Mendaftar...' : controller.submitStatus.value)
          : 'Daftar Sekarang',
      onButtonPressed: controller.isSubmitting.value ? null : controller.handleLanjutkan,
    ));
  }
}
