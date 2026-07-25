// Kumpulan konstanta desain bersama: warna (AppColors) dan gaya teks
// (AppText) berbasis font Poppins, dipakai di hampir semua halaman.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF122C93);
  static const background = Color(0xFFF5F7FF);
  static const cardBorder = Color(0x1A122C93);
  static const disabled = Color(0xFF8D8787);
  static const greyText = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF5F7FF);
  static const fieldBorder = Color(0x338D8787);
  static const progressTrack = Color(0xFFDEE5FF);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFA80808);
}

class AppText {
  AppText._();

  static const TextStyle regular = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400);
  static const TextStyle medium = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500);
  static const TextStyle semiBold = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600);
  static const TextStyle bold = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700);
}
