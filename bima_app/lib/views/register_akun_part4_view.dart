import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/register_akun_part4_controller.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_theme.dart';
import '../widgets/wizard_header.dart';
import '../widgets/wizard_scaffold.dart';

class RegisterAkunPart4View extends GetView<RegisterAkunPart4Controller> {
  const RegisterAkunPart4View({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
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
          AppTextField(
            label: 'Password',
            controller: controller.passwordController,
            hint: 'Masukkan password',
            obscureText: true,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Konfirmasi Ulang Password',
            controller: controller.confirmPasswordController,
            hint: 'konfirmasi ulang password',
            obscureText: true,
          ),
        ],
      ),
      buttonLabel: 'Daftar Sekarang',
      onButtonPressed: controller.handleLanjutkan,
    );
  }
}
