// Controller untuk halaman Beranda: status "sedang bertugas atau tidak"
// (dibaca dari TrackingService, lihat services/tracking_service.dart)
// supaya tombol Check-in di kartu 'Status Hari ini' bisa otomatis berubah
// jadi Check-out setelah check-in berhasil, dan identitas satpam untuk
// kartu sapaan header (nama/nip/jabatan, lewat SatpamProfileService).

import 'package:get/get.dart';

import '../../services/satpam_profile_service.dart';
import '../../services/tracking_service.dart';

class LandingController extends GetxController {
  final isOnDuty = false.obs;
  final profile = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
    loadProfile();
  }

  Future<void> refreshStatus() async {
    isOnDuty.value = await TrackingService().isOnDuty();
  }

  Future<void> loadProfile() async {
    profile.value = await SatpamProfileService().getProfile();
  }

  String get displayNama => (profile.value?['nama'] as String?) ?? '-';
  String get displayNip => (profile.value?['nip'] as String?) ?? '-';

  String get displayJabatan {
    final jabatan = profile.value?['jabatan']?.toString();
    if (jabatan == null || jabatan.isEmpty) return '-';
    return jabatan[0].toUpperCase() + jabatan.substring(1);
  }

  String get displayClient => (profile.value?['client'] as String?) ?? '-';
}
