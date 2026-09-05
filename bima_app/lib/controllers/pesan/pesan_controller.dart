// Controller untuk halaman Pesan (pesan satu arah dari client ke satpam).
//
// Sebelumnya controller ini memanggil endpoint `/posts` yang cuma
// tebakan ("shape belum dikonfirmasi backend") — endpoint yang benar
// sesuai dokumentasi adalah `GET /messages` (daftar), `GET
// /messages/unread-count` (badge jumlah belum dibaca), dan `POST
// /messages/:uuid/read` (tandai terbaca, idempotent).
//
// `isPanic` dipertahankan sebagai field tapi selalu false — konsep
// "pesan bergaya panic alert" di kartu pesan (lihat pesan_view.dart) tidak
// punya sumber data nyata; panic alert adalah fitur terpisah (`/alerts`),
// bukan bagian dari `/messages`.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class PesanItem {
  final String uuid;
  final String title;
  final String time;
  final String preview;
  final String fullBody;
  final bool isPanic;
  bool isRead;

  PesanItem({
    required this.uuid,
    required this.title,
    required this.time,
    required this.preview,
    String? fullBody,
    this.isPanic = false,
    this.isRead = false,
  }) : fullBody = fullBody ?? preview;
}

class PesanController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final messages = <PesanItem>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  String? _cursor;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchMessages();
    fetchUnreadCount();
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> fetchMessages() async {
    isLoading.value = true;
    _cursor = null;
    _hasMore = true;
    try {
      final page = await _fetchPage(cursor: null);
      messages.value = page.items;
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoading.value = false;
    }
  }

  /// Dipanggil saat scroll mendekati bawah daftar (lihat pesan_view.dart).
  /// Endpoint ini keyset-paginated (cursor/limit + meta.has_more/
  /// next_cursor) — bukan offset — jadi halaman berikutnya selalu minta
  /// `next_cursor` dari respons sebelumnya, tidak pernah nomor halaman.
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final page = await _fetchPage(cursor: _cursor);
      messages.addAll(page.items);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<({List<PesanItem> items, String? nextCursor, bool hasMore})> _fetchPage({String? cursor}) async {
    try {
      final response = await GetConnect().get(
        '$BASE_API_URL/messages',
        query: {if (cursor != null) 'cursor': cursor},
        headers: await _authHeaders(),
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final body = ok && response.body is Map ? response.body as Map : null;
      final data = body?['data'];
      if (data is! List) {
        debugPrint('PesanController: gagal ambil pesan (status ${response.statusCode}).');
        return (items: <PesanItem>[], nextCursor: null, hasMore: false);
      }

      final items = data.whereType<Map>().map((m) {
        final createdAt = DateTime.tryParse((m['created_at'] ?? '').toString())?.toLocal();
        final sender = m['sender'] is Map ? Map<String, dynamic>.from(m['sender'] as Map) : null;
        return PesanItem(
          uuid: (m['uuid'] ?? '').toString(),
          title: (m['title'] ?? sender?['nama'] ?? '').toString(),
          time: createdAt != null ? _formatTime(createdAt) : '-',
          preview: (m['content'] ?? '').toString(),
          isRead: m['is_read'] == true,
        );
      }).toList();

      final meta = body?['meta'] is Map ? body!['meta'] as Map : null;
      return (
        items: items,
        nextCursor: meta?['next_cursor']?.toString(),
        hasMore: meta?['has_more'] == true,
      );
    } catch (e) {
      debugPrint('PesanController: gagal ambil pesan: $e');
      return (items: <PesanItem>[], nextCursor: null, hasMore: false);
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await GetConnect().get(
        '$BASE_API_URL/messages/unread-count',
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      final count = data is Map ? data['count'] : null;
      if (count is num) {
        unreadCount.value = count.toInt();
      }
    } catch (e) {
      debugPrint('PesanController: gagal ambil jumlah pesan belum dibaca: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Hari ini · $hm' : '${dt.day}/${dt.month}/${dt.year} · $hm';
  }

  void openMessage(PesanItem item) {
    if (!item.isRead) {
      item.isRead = true;
      messages.refresh();
      if (unreadCount.value > 0) unreadCount.value -= 1;
      _markRead(item.uuid);
    }

    Get.dialog(
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                item.fullBody,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Idempotent di server — aman dipanggil lagi kalau gagal (mis. offline);
  /// state lokal sudah terlanjur menandai terbaca untuk UX yang responsif.
  Future<void> _markRead(String uuid) async {
    if (uuid.isEmpty) return;
    try {
      await GetConnect().post('$BASE_API_URL/messages/$uuid/read', {}, headers: await _authHeaders());
    } catch (e) {
      debugPrint('PesanController: gagal menandai pesan terbaca: $e');
    }
  }
}
