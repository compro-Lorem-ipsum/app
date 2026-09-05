// Controller untuk halaman tambah/ubah kontak darurat pada Profil Saya.
// Mode ubah aktif kalau halaman dibuka dengan `arguments` berisi data
// kontak darurat yang sudah ada (lihat ProfileSayaController.openKontakDarurat).
//
// API (POST/PATCH /emergency-contacts) memakai `hubungan` ∈
// wali,pasangan,anak,saudara — dipetakan dari label Indonesia yang tampil
// di UI lewat _hubunganToApi/_hubunganFromApi.
//
// Hasil disimpan lewat `Get.back(result: true)` kalau create/update/hapus
// berhasil, supaya ProfileSayaController tahu harus memuat ulang daftar
// kontak darurat dari server — bukan mengembalikan datanya sendiri, karena
// server yang menentukan uuid dan validasi (mis. batas 2 kontak aktif).
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class TambahKontakDaruratController extends GetxController {
  static const hubunganOptions = ['Orang Tua', 'Istri/Suami', 'Anak', 'Saudara'];

  static const _hubunganToApi = {
    'Orang Tua': 'wali',
    'Istri/Suami': 'pasangan',
    'Anak': 'anak',
    'Saudara': 'saudara',
  };

  static const hubunganFromApi = {
    'wali': 'Orang Tua',
    'pasangan': 'Istri/Suami',
    'anak': 'Anak',
    'saudara': 'Saudara',
  };

  final namaController = TextEditingController();
  final nomorHpController = TextEditingController();
  final selectedHubungan = Rxn<String>();
  final isDropdownOpen = false.obs;
  final isSubmitting = false.obs;

  bool isEdit = false;
  String? _contactId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      isEdit = true;
      _contactId = args['contactId'] as String?;
      selectedHubungan.value = args['hubungan'] as String?;
      namaController.text = (args['nama'] as String?) ?? '';
      nomorHpController.text = (args['nomorHp'] as String?) ?? '';
    }
  }

  @override
  void onClose() {
    namaController.dispose();
    nomorHpController.dispose();
    super.onClose();
  }

  void toggleDropdown() => isDropdownOpen.value = !isDropdownOpen.value;

  void selectHubungan(String? value) {
    selectedHubungan.value = value;
    isDropdownOpen.value = false;
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<void> handleSimpan() async {
    if (isSubmitting.value) return;

    final nama = namaController.text.trim();
    final nomorHp = nomorHpController.text.trim();
    final hubunganLabel = selectedHubungan.value;

    if (hubunganLabel == null) {
      _showError('Status/Hubungan belum dipilih', 'Pilih status/hubungan kontak darurat Anda.');
      return;
    }
    if (nama.isEmpty) {
      _showError('Nama wajib diisi', 'Masukan nama kontak darurat.');
      return;
    }
    if (nomorHp.isEmpty) {
      _showError('Nomor HP wajib diisi', 'Masukan nomor HP kontak darurat.');
      return;
    }

    final hubunganApi = _hubunganToApi[hubunganLabel]!;

    isSubmitting.value = true;
    try {
      final headers = await _authHeaders();
      final payload = {'nama': nama, 'hubungan': hubunganApi, 'kontak': nomorHp};

      final response = isEdit
          ? await GetConnect().patch('$_baseApiUrl/emergency-contacts/$_contactId', payload, headers: headers)
          : await GetConnect().post('$_baseApiUrl/emergency-contacts', payload, headers: headers);

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        Get.back(result: true);
        return;
      }

      _handleSaveError(response.statusCode, response.body);
    } catch (e) {
      debugPrint('TambahKontakDaruratController: gagal menyimpan kontak darurat: $e');
      _showError('Gagal Menyimpan', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void _handleSaveError(int? statusCode, dynamic body) {
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code']?.toString() : null;
    final rawMessage = (error is Map ? error['message'] : null)?.toString();

    if (code == 'CONTACT_LIMIT_REACHED') {
      _showError('Kontak Darurat Penuh', rawMessage ?? 'Anda sudah memiliki 2 kontak darurat aktif. Hapus salah satu terlebih dahulu.');
      return;
    }

    switch (statusCode) {
      case 422:
        _showError('Data Tidak Valid', rawMessage ?? 'Periksa kembali data yang Anda isi.');
        return;
      case 404:
        _showError('Kontak Tidak Ditemukan', rawMessage ?? 'Kontak ini sudah tidak ada, mungkin sudah dihapus.');
        return;
      default:
        _showError('Gagal Menyimpan', rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.');
    }
  }

  Future<void> handleHapus() async {
    if (isSubmitting.value) return;
    final contactId = _contactId;
    if (contactId == null) {
      Get.back(result: true);
      return;
    }

    isSubmitting.value = true;
    try {
      final headers = await _authHeaders();
      final response = await GetConnect().delete('$_baseApiUrl/emergency-contacts/$contactId', headers: headers);

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        Get.back(result: true);
        return;
      }

      _showError('Gagal Menghapus', 'Terjadi kesalahan, silakan coba lagi.');
    } catch (e) {
      debugPrint('TambahKontakDaruratController: gagal menghapus kontak darurat: $e');
      _showError('Gagal Menghapus', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
    }
  }
}
