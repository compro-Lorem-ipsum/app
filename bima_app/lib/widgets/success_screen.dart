// Layar sukses generik (icon centang animasi + judul + tombol aksi)
// dipakai bersama oleh beberapa alur seperti Unggah Berkas dan
// Pengajuan. Konten utamanya selalu center vertikal di atas tombol.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_theme.dart';
import 'card_container.dart';
import 'primary_button.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, String>? details;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final double? buttonWidth;
  final double buttonHeight;
  final double buttonBorderRadius;
  final double buttonFontSize;

  const SuccessScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.details,
    this.buttonLabel = 'Kembali ke Beranda',
    required this.onButtonPressed,
    this.buttonWidth,
    this.buttonHeight = 50,
    this.buttonBorderRadius = 10,
    this.buttonFontSize = 16,
  });

  Widget _buildIconAndTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: Center(
                child: SvgPicture.asset('assets/icons/check_bold.svg', width: 36, height: 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: AppText.bold.copyWith(fontSize: 22, color: AppColors.primary)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center, style: AppText.regular.copyWith(fontSize: 13, color: AppColors.disabled)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconAndTitle(),
                        if (details != null) ...[
                          const SizedBox(height: 24),
                          CardContainer(
                            child: Column(
                              children: details!.entries
                                  .map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(e.key, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
                                            Text(e.value, style: AppText.semiBold.copyWith(fontSize: 13, color: Colors.black)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: PrimaryButton(
                    label: buttonLabel,
                    onPressed: onButtonPressed,
                    height: buttonHeight,
                    borderRadius: buttonBorderRadius,
                    fontSize: buttonFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
