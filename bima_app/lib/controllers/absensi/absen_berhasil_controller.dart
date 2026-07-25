// Controller untuk layar 'Absen Berhasil' yang muncul setelah proses
// check-in/check-out selesai. Hanya menyimpan data ringkasan untuk
// ditampilkan (jam, status), tidak ada logic API di sini.

import 'package:get/get.dart';

class AbsenBerhasilController extends GetxController {
  late final String waktu;
  late final String lokasi;
  late final String status;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final map = (args is Map) ? args : const <String, dynamic>{};

    waktu = (map['waktu'] as String?) ?? '-';
    lokasi = (map['lokasi'] as String?) ?? 'Pos Utama';
    status = (map['status'] as String?) ?? 'Tepat Waktu';
  }

  void kembaliKeBeranda() => Get.offAllNamed('/');
}
