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
// Membuka/mengunduh file sungguhan (lewat view_url/download_url) belum
// diimplementasikan di sini — proyek ini belum punya dependency untuk
// membuka URL eksternal (mis. url_launcher) atau viewer PDF/gambar in-app,
// jadi tap masih menampilkan notifikasi sementara.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

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

  void openDocument(DokumenItem item) {
    if (!item.isReady) {
      Get.snackbar(
        'Dokumen Belum Siap',
        'Dokumen ini masih diproses server, coba lagi sebentar.',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // TODO: buka item.viewUrl (browser/viewer PDF) begitu ada dependency
    // untuk membuka URL eksternal di proyek ini.
    Get.snackbar(
      'Segera Hadir',
      'Membuka dokumen langsung di aplikasi belum tersedia di versi ini.',
      backgroundColor: primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
