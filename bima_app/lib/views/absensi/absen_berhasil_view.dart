// Tampilan layar sukses setelah check-in/check-out (pakai widget
// SuccessScreen bersama).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/absensi/absen_berhasil_controller.dart';
import '../../widgets/success_screen.dart';

class AbsenBerhasilView extends StatelessWidget {
  const AbsenBerhasilView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AbsenBerhasilController>();

    return SuccessScreen(
      title: 'Berhasil',
      subtitle: 'Absensi Anda telah berhasil disimpan.',
      details: {
        'WAKTU': controller.waktu,
        'LOKASI': controller.lokasi,
        'STATUS': controller.status,
      },
      onButtonPressed: controller.kembaliKeBeranda,
    );
  }
}
