// Controller untuk halaman Pesan (pesan satu arah dari mitra/client).
// Data diambil dari GET /posts (Authorization Bearer token, tanpa body).
// Shape item post belum dikonfirmasi persis oleh backend — diasumsikan
// mengikuti pola yang sama dengan /announcement (title, description,
// datetime), gampang disesuaikan begitu contoh respons asli tersedia.
//
// Item panic alert (isPanic) di layar ini sebelumnya cuma mock/demo UI —
// belum ada mekanisme real-time (push/socket) yang mengisinya, jadi tidak
// ada lagi dummy panic item begitu data asli dari /posts dipakai di sini.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class PesanItem {
  final String title;
  final String time;
  final String preview;
  final String fullBody;
  final bool isPanic;
  bool isRead;

  PesanItem({
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
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    isLoading.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$BASE_API_URL/posts',
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) {
        debugPrint('PesanController: gagal ambil pesan (status ${response.statusCode}).');
        return;
      }

      messages.value = data.whereType<Map>().map((p) {
        final datetime = DateTime.tryParse((p['datetime'] ?? '').toString())?.toLocal();
        return PesanItem(
          title: (p['title'] ?? '').toString(),
          time: datetime != null ? _formatTime(datetime) : '-',
          preview: (p['description'] ?? '').toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('PesanController: gagal ambil pesan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Hari ini · $hm' : '${dt.day}/${dt.month}/${dt.year} · $hm';
  }

  int get unreadCount => messages.where((m) => !m.isRead).length;

  void openMessage(PesanItem item) {
    item.isRead = true;
    messages.refresh();

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
}
