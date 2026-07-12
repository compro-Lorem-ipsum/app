import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'card_container.dart';
import 'primary_button.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, String>? details;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const SuccessScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.details,
    this.buttonLabel = 'Kembali ke Beranda',
    required this.onButtonPressed,
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
              child: const Icon(Icons.check, color: Colors.white, size: 32),
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
    final hasExtraContent = subtitle != null || details != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              if (hasExtraContent) ...[
                const SizedBox(height: 60),
                _buildIconAndTitle(),
              ] else
                Expanded(child: Center(child: _buildIconAndTitle())),
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
              if (hasExtraContent) const Spacer(),
              PrimaryButton(label: buttonLabel, onPressed: onButtonPressed),
            ],
          ),
        ),
      ),
    );
  }
}
