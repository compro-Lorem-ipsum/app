// Controller untuk halaman Profil Saya (data diri satpam yang login).

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/panic_alert_polling_service.dart';
import '../../services/satpam_profile_service.dart';
import 'tambah_kontak_darurat_controller.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class ProfileSayaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);
  static const maxKontakDarurat = 2;

  static const _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // "1"/"2" belum dikonfirmasi persis oleh backend mana yang laki-laki
  // mana yang perempuan — dipetakan dari contoh respons GET /satpam/me
  // yang tersedia ("Alma" -> gender "2").
  static const _genderLabels = {'1': 'Laki - laki', '2': 'Perempuan'};

  final documentsComplete = false.obs;

  /// Data mentah dari GET /satpam/me. Null selama belum termuat / gagal.
  final profile = Rxn<Map<String, dynamic>>();
  final isLoadingProfile = true.obs;

  /// Setiap item: { contactId, nama, hubungan (label Indonesia), nomorHp }.
  final kontakDaruratList = <Map<String, dynamic>>[].obs;
  final isLoadingKontak = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    loadKontakDarurat();
  }

  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    try {
      // forceRefresh: true — halaman Profil Saya adalah sumber kebenaran,
      // jadi selalu ambil data terbaru dari server (bukan cache lama yang
      // mungkin sudah dipakai halaman lain seperti Beranda/Check-in).
      profile.value = await SatpamProfileService().getProfile(forceRefresh: true);
    } finally {
      isLoadingProfile.value = false;
    }
  }

  String _field(String key) {
    final value = profile.value?[key];
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String get displayNama => _field('nama');
  String get displayNip => _field('nip');
  String get displayEmail => _field('email');
  String get displayNrg => _field('nrg');
  String get displayAsalDaerah => _field('asal_daerah');
  String get displayClient => _field('client');
  String get displayKontakUtama => _field('kontak_utama');

  String get displayJabatan {
    final jabatan = profile.value?['jabatan']?.toString();
    if (jabatan == null || jabatan.isEmpty) return '-';
    return jabatan[0].toUpperCase() + jabatan.substring(1);
  }

  String get displayGender => _genderLabels[profile.value?['gender']?.toString()] ?? '-';

  String get displayDateAssigned {
    final raw = profile.value?['date_assigned']?.toString();
    final date = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '-';
    return '${date.day} ${_monthNames[date.month]} ${date.year}';
  }

  Future<void> loadKontakDarurat() async {
    isLoadingKontak.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$_baseApiUrl/emergency-contacts',
        headers: (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = response.body is Map ? response.body['data'] : null;
      if (ok && data is List) {
        kontakDaruratList.value = data.whereType<Map>().map((item) => _fromApi(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('ProfileSayaController: gagal memuat kontak darurat: $e');
    } finally {
      isLoadingKontak.value = false;
    }
  }

  Map<String, dynamic> _fromApi(Map<String, dynamic> item) => {
        'contactId': item['uuid'] ?? item['contact_id'] ?? item['id'],
        'nama': (item['nama'] ?? '').toString(),
        'hubungan': TambahKontakDaruratController.hubunganFromApi[item['hubungan']] ?? (item['hubungan'] ?? '').toString(),
        'nomorHp': (item['kontak'] ?? '').toString(),
      };

  void openDocuments() {
    Get.toNamed('/unggah-berkas');
  }

  Future<void> openKontakDarurat({Map<String, dynamic>? existing}) async {
    final result = await Get.toNamed('/tambah-kontak-darurat', arguments: existing);
    if (result == true) {
      await loadKontakDarurat();
    }
  }

  Future<void> logout() async {
    await PanicAlertPollingService().stop();
    SatpamProfileService().clear();
    await AuthService().logout();
    Get.offAllNamed('/login');
  }
}
