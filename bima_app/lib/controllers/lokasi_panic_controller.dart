import 'package:get/get.dart';

class LokasiPanicController extends GetxController {
  late final String satpamName;
  late final String nip;
  late final String mitra;
  late final String time;
  late final double latitude;
  late final double longitude;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final data = args is Map ? args : const <String, dynamic>{};

    satpamName = data['satpamName'] as String? ?? 'Nama Satpam';
    nip = data['nip'] as String? ?? 'NIP 123xxx';
    mitra = data['mitra'] as String? ?? 'Nama Mitra';
    time = data['time'] as String? ?? 'Hari ini · 02:31';
    latitude = (data['latitude'] as num?)?.toDouble() ?? -6.9088;
    longitude = (data['longitude'] as num?)?.toDouble() ?? 107.6151;
  }
}
