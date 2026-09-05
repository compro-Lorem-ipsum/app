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
// Membuka dokumen lewat viewer in-app (DocumentViewerView, PDF via pdfx /
// gambar via Image.network) — lihat document_viewer_controller.dart.

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
  final isLoadingMore = false.obs;

  String? _cursor;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadDokumen();
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> loadDokumen() async {
    isLoading.value = true;
    _cursor = null;
    _hasMore = true;
    try {
      final page = await _fetchPage(cursor: null);
      dokumen.value = page.items;
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreDokumen() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final page = await _fetchPage(cursor: _cursor);
      dokumen.addAll(page.items);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<({List<DokumenItem> items, String? nextCursor, bool hasMore})> _fetchPage({String? cursor}) async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/shared-documents',
        query: {if (cursor != null) 'cursor': cursor},
        headers: await _authHeaders(),
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final body = ok && response.body is Map ? response.body as Map : null;
      final data = body?['data'];
      if (data is! List) {
        debugPrint('RepDoksController: gagal memuat dokumen repositori (status ${response.statusCode}).');
        return (items: <DokumenItem>[], nextCursor: null, hasMore: false);
      }

      final items = data.whereType<Map>().map((item) => DokumenItem.fromApi(Map<String, dynamic>.from(item))).toList();
      final meta = body?['meta'] is Map ? body!['meta'] as Map : null;
      return (
        items: items,
        nextCursor: meta?['next_cursor']?.toString(),
        hasMore: meta?['has_more'] == true,
      );
    } catch (e) {
      debugPrint('RepDoksController: gagal memuat dokumen repositori: $e');
      return (items: <DokumenItem>[], nextCursor: null, hasMore: false);
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

  void openDocument(DokumenItem item) {
    if (!item.isReady) {
      _showMessage('Dokumen Belum Siap', 'Dokumen ini masih diproses server, coba lagi sebentar.');
      return;
    }

    final url = item.viewUrl;
    if (url == null || Uri.tryParse(url) == null) {
      _showMessage('Gagal Membuka', 'Tautan dokumen tidak valid.');
      return;
    }

    Get.toNamed('/document-viewer', arguments: {'url': url, 'nama': item.nama});
  }
}
