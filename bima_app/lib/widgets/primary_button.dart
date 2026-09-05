// Tombol utama bergaya seragam (warna, radius, ukuran font bisa
// dikustomisasi) dipakai di hampir semua halaman sebagai tombol aksi.
//
// Varian [outlined] dipakai untuk aksi sekunder/peringatan dengan latar
// putih dan garis tepi berwarna — mis. tombol "Upload Ulang" merah di
// halaman Upload PAS Foto saat backend menolak foto (Figma node 44:1055).

import 'package:flutter/material.dart';
import 'app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color? color;
  final double borderRadius;
  final double fontSize;

  /// Kalau true: latar putih, garis tepi [color], teks [textColor]
  /// (default: sama dengan [color]). Kalau false: tombol solid biasa.
  final bool outlined;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.color,
    this.borderRadius = 10,
    this.fontSize = 16,
    this.outlined = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.primary;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius));

    final Widget button;
    if (outlined) {
      final foreground = textColor ?? baseColor;
      button = OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: foreground,
          disabledForegroundColor: foreground.withValues(alpha: 0.4),
          side: BorderSide(color: onPressed == null ? baseColor.withValues(alpha: 0.4) : baseColor),
          shape: shape,
        ),
        onPressed: onPressed,
        child: Text(label, style: AppText.bold.copyWith(fontSize: fontSize)),
      );
    } else {
      button = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: baseColor.withValues(alpha: 0.4),
          shape: shape,
        ),
        onPressed: onPressed,
        child: Text(label, style: AppText.bold.copyWith(fontSize: fontSize)),
      );
    }

    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
