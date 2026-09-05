// Controller untuk halaman 'Aktifitas Saya' (riwayat absensi & patroli).
// Digabung dari GET /attendance dan GET /patrols (satpam otomatis hanya
// lihat rekam miliknya sendiri di keduanya).
//
// Infinite scroll pada layar gabungan ("Semua") itu rumit karena dua
// sumber yang masing-masing keyset-paginated sendiri-sendiri harus
// digabung lalu dikelompokkan ulang per tanggal. Solusinya: simpan
// SELURUH entri mentah yang sudah pernah diambil dari kedua sumber
// (_absensiRaw/_patroliRaw), lacak cursor & has_more masing-masing
// TERPISAH, dan setiap kali ada halaman baru dari salah satu/kedua
// sumber, seluruh entri mentah yang terkumpul di-regroup ulang dari nol
// (bukan cuma di-append) supaya urutan tanggal tetap benar. "Muat lagi"
// otomatis berhenti kalau KEDUA sumber sudah habis (has_more keduanya
// false).
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
  final isLoadingMore = false.obs;

  final _absensiGroups = <ActivityGroup>[].obs;
  final _patroliGroups = <ActivityGroup>[].obs;
  final _semuaGroups = <ActivityGroup>[].obs;

  final List<_DatedEntry> _absensiRaw = [];
  final List<_DatedEntry> _patroliRaw = [];
  String? _absensiCursor;
  String? _patroliCursor;
  bool _absensiHasMore = true;
  bool _patroliHasMore = true;

  bool get _hasMoreAny => _absensiHasMore || _patroliHasMore;

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
    _absensiRaw.clear();
    _patroliRaw.clear();
    _absensiCursor = null;
    _patroliCursor = null;
    _absensiHasMore = true;
    _patroliHasMore = true;
    try {
      await Future.wait([_loadMoreAttendancePage(), _loadMorePatrolPage()]);
      _regroup();
    } finally {
      isLoading.value = false;
    }
  }

  /// Dipanggil saat scroll mendekati bawah daftar (lihat
  /// aktifitas_saya_view.dart). Minta halaman berikutnya dari SETIAP
  /// sumber yang masih punya `has_more` — layar "Semua" mencampur
  /// keduanya, jadi tidak bisa tahu dari posisi scroll saja sumber mana
  /// yang perlu ditambah, aman meminta keduanya sekaligus.
  Future<void> loadMoreActivity() async {
    if (isLoadingMore.value || !_hasMoreAny) return;
    isLoadingMore.value = true;
    try {
      final futures = <Future<void>>[];
      if (_absensiHasMore) futures.add(_loadMoreAttendancePage());
      if (_patroliHasMore) futures.add(_loadMorePatrolPage());
      await Future.wait(futures);
      _regroup();
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _regroup() {
    _absensiGroups.value = _group(_absensiRaw);
    _patroliGroups.value = _group(_patroliRaw);
    _semuaGroups.value = _group([..._absensiRaw, ..._patroliRaw]);
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

Future<void> _loadMoreAttendancePage() async {
    final page = await _fetchAttendancePage(cursor: _absensiCursor);
    _absensiRaw.addAll(page.items);
    _absensiCursor = page.nextCursor;
    _absensiHasMore = page.hasMore;
  }

  Future<void> _loadMorePatrolPage() async {
    final page = await _fetchPatrolPage(cursor: _patroliCursor);
    _patroliRaw.addAll(page.items);
    _patroliCursor = page.nextCursor;
    _patroliHasMore = page.hasMore;
  }

  Future<({List<_DatedEntry> items, String? nextCursor, bool hasMore})> _fetchAttendancePage({String? cursor}) async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/attendance',
        query: {if (cursor != null) 'cursor': cursor},
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final body = ok && response.body is Map ? response.body as Map : null;
      final data = body?['data'];
      if (data is! List) return (items: <_DatedEntry>[], nextCursor: null, hasMore: false);

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

      final meta = body?['meta'] is Map ? body!['meta'] as Map : null;
      return (
        items: out,
        nextCursor: meta?['next_cursor']?.toString(),
        hasMore: meta?['has_more'] == true,
      );
    } catch (e) {
      debugPrint('AktifitasSayaController: gagal ambil riwayat absensi: $e');
      return (items: <_DatedEntry>[], nextCursor: null, hasMore: false);
    }
  }

  Future<({List<_DatedEntry> items, String? nextCursor, bool hasMore})> _fetchPatrolPage({String? cursor}) async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/patrols',
        query: {if (cursor != null) 'cursor': cursor},
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final body = ok && response.body is Map ? response.body as Map : null;
      final data = body?['data'];
      if (data is! List) return (items: <_DatedEntry>[], nextCursor: null, hasMore: false);

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

      final meta = body?['meta'] is Map ? body!['meta'] as Map : null;
      return (
        items: out,
        nextCursor: meta?['next_cursor']?.toString(),
        hasMore: meta?['has_more'] == true,
      );
    } catch (e) {
      debugPrint('AktifitasSayaController: gagal ambil riwayat patroli: $e');
      return (items: <_DatedEntry>[], nextCursor: null, hasMore: false);
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
