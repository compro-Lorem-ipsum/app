// Tampilan langkah 1 Lupa Password: input email untuk kirim OTP.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/auth/lupa_password_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class LupaPasswordPart1View extends GetView<LupaPasswordController> {
  const LupaPasswordPart1View({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => WizardScaffold(
      header: WizardHeader(
        currentStep: 1,
        totalSteps: 2,
        stepLabel: 'Reset Password',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 95,
                  height: 95,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(20)),
                  child: SvgPicture.asset('assets/icons/mail_lock.svg', width: 55, height: 55),
                ),
                const SizedBox(height: 20),
                Text('Lupa Password', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email akun Anda. Kode OTP akan dikirim untuk reset password.',
                  textAlign: TextAlign.center,
                  style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Email',
            controller: controller.emailController,
            hint: 'nama@gmail.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      buttonLabel: controller.isSendingOtp.value ? 'Mengirim...' : 'Kirim OTP',
      onButtonPressed: controller.isSendingOtp.value ? null : controller.handleKirimOtp,
    ));
  }
}
