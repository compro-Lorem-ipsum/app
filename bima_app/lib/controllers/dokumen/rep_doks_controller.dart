// Controller untuk halaman Dokumen Repositori — dokumen yang
// dipublikasikan admin ke satpam/client (GET /shared-documents).
//
// Respons untuk satpam TIDAK menyertakan field `recipient` (hanya admin
// yang melihat daftar penerima) — sesuai dokumentasi Shared Documents.
// `file.view_url`/`file.download_url` bernilai null sampai
// `file.status == "VALID"` (upload divalidasi async di backend); dokumen
// yang masih PENDING ditandai lewat [DokumenItem.isReady], bukan
// disembunyikan begitu saja.
//
// Membuka dokumen lewat `view_url` di browser/viewer eksternal device
// (lewat url_launcher) — proyek ini belum punya viewer PDF/gambar in-app,
// jadi ini pendekatan paling sederhana yang tetap benar-benar berfungsi.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class DokumenItem {
  final String uuid;
  final String nama;
  final String? deskripsi;
  final DateTime? createdAt;
  final String fileStatus;
  final String? viewUrl;
  final String? downloadUrl;

  DokumenItem({
    required this.uuid,
    required this.nama,
    this.deskripsi,
    this.createdAt,
    required this.fileStatus,
    this.viewUrl,
    this.downloadUrl,
  });

  bool get isReady => fileStatus == 'VALID' && viewUrl != null;

  factory DokumenItem.fromApi(Map<String, dynamic> json) {
    final file = json['file'] is Map ? Map<String, dynamic>.from(json['file'] as Map) : null;
    return DokumenItem(
      uuid: (json['uuid'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      deskripsi: json['deskripsi']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      fileStatus: (file?['status'] ?? 'PENDING').toString(),
      viewUrl: file?['view_url']?.toString(),
      downloadUrl: file?['download_url']?.toString(),
    );
  }
}

class RepDoksController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  static const _bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  final dokumen = <DokumenItem>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDokumen();
  }

  Future<void> loadDokumen() async {
    isLoading.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$_baseApiUrl/shared-documents',
        headers: (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = response.body is Map ? response.body['data'] : null;
      if (ok && data is List) {
        dokumen.value = data.whereType<Map>().map((item) => DokumenItem.fromApi(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('RepDoksController: gagal memuat dokumen repositori: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String formatTanggal(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')} ${_bulan[date.month]} ${date.year}';
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> openDocument(DokumenItem item) async {
    if (!item.isReady) {
      _showMessage('Dokumen Belum Siap', 'Dokumen ini masih diproses server, coba lagi sebentar.');
      return;
    }

    final url = item.viewUrl;
    if (url == null) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Gagal Membuka', 'Tautan dokumen tidak valid.');
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showMessage('Gagal Membuka', 'Tidak ada aplikasi yang bisa membuka dokumen ini.');
      }
    } catch (e) {
      debugPrint('RepDoksController: gagal membuka dokumen: $e');
      _showMessage('Gagal Membuka', 'Terjadi kesalahan saat membuka dokumen.');
    }
  }
}
