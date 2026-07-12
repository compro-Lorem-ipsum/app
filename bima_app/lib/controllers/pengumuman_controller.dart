import 'package:get/get.dart';
import '../views/isi_pengumuman_view.dart';

class PengumumanController extends GetxController {
  final announcements = <Map<String, dynamic>>[
    {
      'title': 'Briefing Akhir Tahun Bersama',
      'date': '31 Des 2027',
      'time': '07:00',
      'summary': 'Mohon hadir di kantor pusat pada 31 Januari pukul 09:00 untuk briefing penutupan tahun.',
      'body':
          'Mohon hadir di kantor pusat pada 31 Januari pukul 09:00 untuk briefing penutupan tahun.\n\n'
          'Agenda:\n'
          '• Evaluasi kinerja Q4\n'
          '• Penyampaian rencana 2026\n'
          '• Apresiasi personel terbaik\n'
          '• Sosialisasi SOP baru\n\n'
          'Wajib hadir tepat waktu dengan seragam lengkap.',
      'admin': 'ADMIN BGS',
      'unread': true,
    },
    {
      'title': 'Judul Pengumuman',
      'date': '31 Des 2027',
      'time': '07:00',
      'summary': 'Deskripsi ringkas Pengumuman',
      'body': 'Deskripsi ringkas Pengumuman',
      'admin': 'ADMIN BGS',
      'unread': true,
    },
    {
      'title': 'Judul Pengumuman',
      'date': '31 Des 2027',
      'time': '07:00',
      'summary': 'Deskripsi ringkas Pengumuman',
      'body': 'Deskripsi ringkas Pengumuman',
      'admin': 'ADMIN BGS',
      'unread': false,
    },
    {
      'title': 'Judul Pengumuman',
      'date': '31 Des 2027',
      'time': '07:00',
      'summary': 'Deskripsi ringkas Pengumuman',
      'body': 'Deskripsi ringkas Pengumuman',
      'admin': 'ADMIN BGS',
      'unread': false,
    },
  ].obs;

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
