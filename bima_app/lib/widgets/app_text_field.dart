// Text field bergaya seragam (label + input) dipakai di seluruh form
// aplikasi; mendukung obscureText & suffixIcon untuk kasus seperti
// toggle show/hide password.

import 'package:flutter/cupertino.dart';
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
  final TextInputAction? textInputAction;

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
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final effectiveKeyboardType = (maxLines > 1 && keyboardType == TextInputType.text) ? TextInputType.multiline : keyboardType;
    final effectiveAction = textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.done);
    final autocorr = !obscureText && effectiveKeyboardType != TextInputType.emailAddress && effectiveKeyboardType != TextInputType.visiblePassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: effectiveKeyboardType,
          textInputAction: effectiveAction,
          maxLines: maxLines,
          obscureText: obscureText,
          autocorrect: autocorr,
          enableSuggestions: !obscureText,
          cursorColor: AppColors.primary,
          cursorWidth: isIOS ? 1.8 : 2.0,
          cursorRadius: isIOS ? const Radius.circular(2) : Radius.zero,
          selectionControls: isIOS ? cupertinoTextSelectionControls : materialTextSelectionControls,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: AppText.regular.copyWith(fontSize: 13, color: Colors.black),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled),
            filled: true,
            fillColor: AppColors.fieldFill,
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
