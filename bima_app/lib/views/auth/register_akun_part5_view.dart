// Tampilan langkah 5 (terakhir) pendaftaran akun.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_part5_controller.dart';
import '../../widgets/bubble_success_screen.dart';

class RegisterAkunPart5View extends GetView<RegisterAkunPart5Controller> {
  const RegisterAkunPart5View({super.key});

  @override
  Widget build(BuildContext context) {
    return BubbleSuccessScreen(
      title: 'Akun Berhasil dibuat',
      subtitle: 'Akun Anda akan diverifikasi admin sebelum dapat digunakan. Notifikasi akan dikirim ke email & No HP.',
      buttonLabel: 'Kembali ke Login',
      onButtonPressed: controller.handleKembaliKeLogin,
    );
  }
}
