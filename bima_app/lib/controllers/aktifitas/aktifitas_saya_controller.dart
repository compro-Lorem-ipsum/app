// Controller untuk halaman 'Aktifitas Saya' (riwayat absensi & patroli).
// Digabung dari GET /attendance (satpam otomatis hanya lihat rekam
// miliknya sendiri) dan GET /patrols (idem), masing-masing diambil satu
// halaman pertama (limit 50) — belum ada infinite-scroll/"muat lagi",
// sama seperti pola di halaman list lain (Pesan/Pengajuan/Dokumen
// Repositori) di proyek ini.
//
// Satu record absensi bisa menghasilkan DUA entri (check-in & check-out)
// kalau keduanya sudah ada, mengikuti desain UI asli. Bentuk field pos di
// dalam record absensi/patroli belum dicontohkan persis oleh backend,
// jadi dibaca defensif (lihat _posLabel) — kalau tidak ketemu, tampil
// label generik daripada mengarang nama pos.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/attendance_summary_service.dart';
import '../../services/auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

enum ActivityType { checkIn, checkOut, patroli }

class ActivityEntry {
  final ActivityType type;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? badgeBg;
  final String? trailing;

  ActivityEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.badgeColor,
    this.badgeBg,
    this.trailing,
  });
}

class ActivityGroup {
  final String date;
  final List<ActivityEntry> entries;

  ActivityGroup({required this.date, required this.entries});
}

class _DatedEntry {
  final DateTime time;
  final ActivityEntry entry;
  _DatedEntry(this.time, this.entry);
}

class AktifitasSayaController extends GetxController {
  static const green = Color(0xFF008236);
  static const greenBg = Color(0xFFDCFCE7);
  static const yellow = Color(0xFF894B00);
  static const yellowBg = Color(0xFFFEF9C2);
  static const red = Color(0xFFC10007);
  static const redBg = Color(0xFFFFE2E2);
  static const primaryColor = Color(0xFF122C93);
  static const primaryBg = Color(0xFFDBEAFE);

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  final selectedFilter = 'Semua'.obs;
  final isLoading = true.obs;

  final _absensiGroups = <ActivityGroup>[].obs;
  final _patroliGroups = <ActivityGroup>[].obs;
  final _semuaGroups = <ActivityGroup>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadActivity();
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> loadActivity() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([_fetchAttendanceEntries(), _fetchPatrolEntries()]);
      final absensiEntries = results[0];
      final patroliEntries = results[1];
      _absensiGroups.value = _group(absensiEntries);
      _patroliGroups.value = _group(patroliEntries);
      _semuaGroups.value = _group([...absensiEntries, ...patroliEntries]);
    } finally {
      isLoading.value = false;
    }
  }

  String _jam(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatTanggalPanjang(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month]} ${d.year}';

  String _posLabel(Map<String, dynamic> record, String fallback) {
    final directPos = record['pos'];
    if (directPos is Map && directPos['nama'] != null) return directPos['nama'].toString();
    final shift = record['shift'];
    if (shift is Map) {
      final shiftPos = shift['pos'];
      if (shiftPos is Map && shiftPos['nama'] != null) return shiftPos['nama'].toString();
    }
    return fallback;
  }

  ({String label, Color color, Color bg})? _statusBadge(String status) {
    switch (status) {
      case 'present':
        return (label: 'Tepat Waktu', color: green, bg: greenBg);
      case 'late':
        return (label: 'Terlambat', color: yellow, bg: yellowBg);
      case 'absent':
        return (label: 'Tidak Hadir', color: red, bg: redBg);
      case 'excused':
        return (label: 'Izin/Cuti', color: primaryColor, bg: primaryBg);
      case 'partial':
        return (label: 'Belum Check-out', color: yellow, bg: yellowBg);
      default:
        return null;
    }
  }

  Future<List<_DatedEntry>> _fetchAttendanceEntries() async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/attendance',
        query: {'limit': '50'},
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return [];

      final out = <_DatedEntry>[];
      for (final raw in data.whereType<Map>()) {
        final record = Map<String, dynamic>.from(raw);
        final posLabel = _posLabel(record, 'Absensi');
        final checkedOut = DateTime.tryParse((record['checked_out_at'] ?? '').toString())?.toLocal();
        final checkedIn = DateTime.tryParse((record['checked_in_at'] ?? '').toString())?.toLocal();

        if (checkedOut != null) {
          out.add(_DatedEntry(
            checkedOut,
            ActivityEntry(
              type: ActivityType.checkOut,
              title: 'Check - out',
              subtitle: '$posLabel · ${_jam(checkedOut)}',
              trailing: AttendanceSummaryService.formatJamMenit(record['worked_minutes'] as num?),
            ),
          ));
        }

        if (checkedIn != null) {
          final badge = _statusBadge((record['status'] ?? '').toString());
          out.add(_DatedEntry(
            checkedIn,
            ActivityEntry(
              type: ActivityType.checkIn,
              title: 'Check - in',
              subtitle: '$posLabel · ${_jam(checkedIn)}',
              badgeLabel: badge?.label,
              badgeColor: badge?.color,
              badgeBg: badge?.bg,
            ),
          ));
        }
      }
      return out;
    } catch (e) {
      debugPrint('AktifitasSayaController: gagal ambil riwayat absensi: $e');
      return [];
    }
  }

  Future<List<_DatedEntry>> _fetchPatrolEntries() async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/patrols',
        query: {'limit': '50'},
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return [];

      final out = <_DatedEntry>[];
      for (final raw in data.whereType<Map>()) {
        final record = Map<String, dynamic>.from(raw);
        final time = DateTime.tryParse((record['created_at'] ?? '').toString())?.toLocal();
        if (time == null) continue;

        final posLabel = _posLabel(record, 'Pos Jaga');
        final isAman = (record['status'] ?? '').toString() == 'aman';
        out.add(_DatedEntry(
          time,
          ActivityEntry(
            type: ActivityType.patroli,
            title: 'Laporan Patroli',
            subtitle: '$posLabel · ${_jam(time)}',
            badgeLabel: isAman ? 'Aman' : 'Tidak Aman',
            badgeColor: isAman ? green : red,
            badgeBg: isAman ? greenBg : redBg,
          ),
        ));
      }
      return out;
    } catch (e) {
      debugPrint('AktifitasSayaController: gagal ambil riwayat patroli: $e');
      return [];
    }
  }

  List<ActivityGroup> _group(List<_DatedEntry> items) {
    final sorted = [...items]..sort((a, b) => b.time.compareTo(a.time));
    final order = <String>[];
    final byLabel = <String, List<ActivityEntry>>{};
    for (final item in sorted) {
      final label = _formatTanggalPanjang(DateTime(item.time.year, item.time.month, item.time.day));
      if (!byLabel.containsKey(label)) {
        byLabel[label] = [];
        order.add(label);
      }
      byLabel[label]!.add(item.entry);
    }
    return order.map((label) => ActivityGroup(date: label, entries: byLabel[label]!)).toList();
  }

  List<ActivityGroup> get currentGroups {
    switch (selectedFilter.value) {
      case 'Absensi':
        return _absensiGroups;
      case 'Patroli':
        return _patroliGroups;
      default:
        return _semuaGroups;
    }
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }
}
