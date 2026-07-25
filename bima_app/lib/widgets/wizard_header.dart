// Header bersama untuk alur wizard (mis. pendaftaran akun): tombol
// back/close, indikator langkah (step), dan label langkah saat ini.

import 'package:flutter/material.dart';
import 'app_theme.dart';

class WizardHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepLabel;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const WizardHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back, size: 22, color: Colors.black),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(height: 5, color: AppColors.progressTrack),
                    FractionallySizedBox(
                      widthFactor: currentStep / totalSteps,
                      child: Container(height: 5, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.close, size: 22, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Langkah $currentStep dari $totalSteps', style: AppText.semiBold.copyWith(fontSize: 14, color: AppColors.primary)),
            Text(stepLabel, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
          ],
        ),
      ],
    );
  }
}
