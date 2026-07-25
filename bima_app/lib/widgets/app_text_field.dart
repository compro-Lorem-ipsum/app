// Text field bergaya seragam (label + input) dipakai di seluruh form
// aplikasi; mendukung obscureText & suffixIcon untuk kasus seperti
// toggle show/hide password.

import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;
  final double borderRadius;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.borderRadius = 10,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          style: AppText.regular.copyWith(fontSize: 12, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled),
            filled: true,
            fillColor: AppColors.fieldFill,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: AppColors.fieldBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: AppColors.fieldBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
