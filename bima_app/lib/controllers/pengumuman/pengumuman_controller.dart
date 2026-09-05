// Controller untuk daftar Pengumuman dan halaman detail/isi pengumuman.
// Data diambil dari GET /announcements (Authorization Bearer token, tanpa
// body) — sebelumnya salah ketik ke /announcement (tunggal) sehingga
// pengumuman yang sudah di-post admin tidak pernah termuat. Status baca/
// belum-dibaca murni lokal di sisi klien — API belum menyediakan konsep
// itu, jadi semua pengumuman dianggap "belum dibaca" sampai pengguna
// membuka detailnya.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../views/pengumuman/isi_pengumuman_view.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class PengumumanController extends GetxController {
  static const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  final announcements = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    isLoading.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$BASE_API_URL/announcements',
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) {
        debugPrint('PengumumanController: gagal ambil pengumuman (status ${response.statusCode}).');
        return;
      }

      announcements.value = data.whereType<Map>().map((a) {
        final datetime = DateTime.tryParse((a['datetime'] ?? '').toString())?.toLocal();
        return <String, dynamic>{
          'uuid': a['uuid'],
          'title': (a['title'] ?? '').toString(),
          'date': datetime != null ? _formatDate(datetime) : '-',
          'time': datetime != null ? _formatTime(datetime) : '-',
          'summary': (a['description'] ?? '').toString(),
          'body': (a['description'] ?? '').toString(),
          'location': (a['location'] ?? '').toString(),
          'unread': true,
        };
      }).toList();
    } catch (e) {
      debugPrint('PengumumanController: gagal ambil pengumuman: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime dt) => '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}';

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  int get unreadCount => announcements.where((a) => a['unread'] == true).length;

  void openAnnouncement(Map<String, dynamic> announcement) {
    final index = announcements.indexOf(announcement);
    if (index != -1) {
      announcements[index] = {...announcement, 'unread': false};
    }
    showIsiPengumumanDialog(announcement);
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }
}
