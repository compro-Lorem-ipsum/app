import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_theme.dart';
import '../widgets/primary_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -105,
            right: -100,
            child: SvgPicture.asset('assets/images/success/login_blob.svg', width: 329, height: 329),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100),
                          Text('Masuk', style: AppText.semiBold.copyWith(fontSize: 24, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text(
                            'Gunakan NIP atau email & password Anda',
                            style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled),
                          ),
                          const SizedBox(height: 28),
                          AppTextField(
                            label: 'NIP atau email',
                            controller: controller.nipController,
                            hint: 'Masukan NIP atau Email',
                            keyboardType: TextInputType.text,
                            borderRadius: 20,
                          ),
                          const SizedBox(height: 20),
                          Obx(() => AppTextField(
                                label: 'Password',
                                controller: controller.passwordController,
                                hint: 'Masukan Password',
                                obscureText: controller.obscurePassword.value,
                                borderRadius: 20,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppColors.disabled,
                                    size: 20,
                                  ),
                                  onPressed: controller.togglePasswordVisibility,
                                ),
                              )),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: controller.toggleRememberMe,
                                child: Row(
                                  children: [
                                    Obx(() => Checkbox(
                                          value: controller.rememberMe.value,
                                          onChanged: (_) => controller.toggleRememberMe(),
                                          activeColor: AppColors.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        )),
                                    const SizedBox(width: 4),
                                    const Text('Ingat Saya', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.handleLupaPassword,
                                child: Text('Lupa Password?', style: AppText.semiBold.copyWith(fontSize: 12, color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(label: 'Masuk', onPressed: controller.handleMasuk, borderRadius: 20),
                          const SizedBox(height: 24),
                          Container(height: 1, color: AppColors.cardBorder),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: controller.handleDaftar,
                              child: RichText(
                                text: TextSpan(
                                  style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled),
                                  children: [
                                    const TextSpan(text: 'Belum Punya Akun?   '),
                                    TextSpan(text: 'Daftar di sini', style: AppText.semiBold.copyWith(fontSize: 12, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Text('BIMA GLOBAL SECURITY', style: AppText.semiBold.copyWith(fontSize: 10, color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text('v2.0.0', style: AppText.regular.copyWith(fontSize: 9, color: AppColors.disabled)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
