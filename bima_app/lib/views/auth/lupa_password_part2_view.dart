// Tampilan langkah 2 Lupa Password: input OTP, password baru, dan
// konfirmasi password baru — keduanya punya tombol show/hide.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/lupa_password_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class LupaPasswordPart2View extends GetView<LupaPasswordController> {
  const LupaPasswordPart2View({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => WizardScaffold(
      header: WizardHeader(
        currentStep: 2,
        totalSteps: 2,
        stepLabel: 'Reset Password',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF02A758)),
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppText.regular.copyWith(fontSize: 14, color: const Color(0xFF008236)),
                children: const [
                  TextSpan(text: 'Kode OTP telah dikirim ke '),
                  TextSpan(text: 'email Anda', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                  TextSpan(text: '. Cek kotak masuk / spam.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Kode OTP', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildOtpBox(i)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: controller.isSendingOtp.value ? null : controller.handleKirimUlang,
              child: Text(
                controller.isSendingOtp.value ? 'Mengirim...' : 'Kirim Ulang',
                style: AppText.semiBold.copyWith(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => AppTextField(
                label: 'Password Baru',
                controller: controller.newPasswordController,
                hint: 'Masukan Password Baru Anda',
                obscureText: controller.obscureNewPassword.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureNewPassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.disabled,
                    size: 20,
                  ),
                  onPressed: controller.toggleNewPasswordVisibility,
                ),
              )),
          const SizedBox(height: 20),
          Obx(() => AppTextField(
                label: 'Konfirmasi Password',
                controller: controller.confirmPasswordController,
                hint: 'Konfirmasi Password Baru Anda',
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
      buttonLabel: controller.isResetting.value ? 'Memproses...' : 'Reset Password',
      onButtonPressed: controller.isResetting.value ? null : controller.handleResetPassword,
    ));
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        onChanged: (value) => controller.handleOtpChanged(index, value),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppText.semiBold.copyWith(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.fieldFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.fieldBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.fieldBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
    );
  }
}
