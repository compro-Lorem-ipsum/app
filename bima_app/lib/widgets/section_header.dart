import 'package:flutter/material.dart';
import 'app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const SectionHeader({super.key, required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('Lihat Semua', style: AppText.medium.copyWith(fontSize: 12, color: AppColors.primary)),
        ),
      ],
    );
  }
}
