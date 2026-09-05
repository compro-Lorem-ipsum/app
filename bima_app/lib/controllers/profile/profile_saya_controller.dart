// Controller untuk halaman Profil Saya (data diri satpam yang login).

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import 'tambah_kontak_darurat_controller.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class ProfileSayaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);
  static const maxKontakDarurat = 2;

  final documentsComplete = false.obs;

  /// Setiap item: { contactId, nama, hubungan (label Indonesia), nomorHp }.
  final kontakDaruratList = <Map<String, dynamic>>[].obs;
  final isLoadingKontak = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadKontakDarurat();
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
    await AuthService().logout();
    Get.offAllNamed('/login');
  }
}
