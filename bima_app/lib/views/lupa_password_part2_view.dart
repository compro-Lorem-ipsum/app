import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lupa_password_controller.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_theme.dart';
import '../widgets/wizard_header.dart';
import '../widgets/wizard_scaffold.dart';

class LupaPasswordPart2View extends GetView<LupaPasswordController> {
  const LupaPasswordPart2View({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
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
              onTap: controller.handleKirimUlang,
              child: Text('Kirim Ulang', style: AppText.semiBold.copyWith(fontSize: 12, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Password Baru',
            controller: controller.newPasswordController,
            hint: 'Masukan Password Baru Anda',
            obscureText: true,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Konfirmasi Password',
            controller: controller.confirmPasswordController,
            hint: 'Konfirmasi Password Baru Anda',
            obscureText: true,
          ),
        ],
      ),
      buttonLabel: 'Reset Password',
      onButtonPressed: controller.handleResetPassword,
    );
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
