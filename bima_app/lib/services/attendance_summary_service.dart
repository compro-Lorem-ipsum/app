// Ringkasan jam kerja & absensi hari ini — dipakai Beranda dan Profil
// Saya untuk kartu statistik durasi. Selalu fetch baru (TIDAK di-cache
// seperti SatpamProfileService) karena datanya berubah tiap kali
// check-in/check-out, beda dari identitas satpam yang jarang berubah.
//
// GET /attendance/working-hours -> { data: { today: {minutes,hours,
// shifts}, this_month: {...}, all_time: {...}, since } }
//
// GET /attendance/today -> { data: { records: [...], shifts: [...] },
// meta: { date } } — BUKAN list langsung (asumsi lama salah, sempat bikin
// fetchToday() diam-diam selalu gagal parse karena cek `data is List`
// padahal `data` itu object). Bentuk asli, dikonfirmasi lewat respons
// nyata:
// - `records`: entri absensi (check-in/out) yang SUDAH tercatat hari ini.
// - `shifts`: jadwal shift hari ini (bisa >1), tiap elemen punya
//   `starts_at`/`ends_at` (ISO UTC), `pos` { uuid, nama } KHUSUS untuk
//   shift itu (tanpa lat/lng — perlu GET /posts/:uuid terpisah kalau
//   butuh koordinat, lihat AbsenCheckinController), dan `attendance`
//   (null kalau shift itu belum di-checkin).

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class AttendanceSummaryService {
  AttendanceSummaryService._internal();
  static final AttendanceSummaryService _instance = AttendanceSummaryService._internal();
  factory AttendanceSummaryService() => _instance;

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>?> fetchWorkingHours() async {
    try {
      final response = await GetConnect().get('$_baseApiUrl/attendance/working-hours', headers: await _authHeaders());
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = response.body is Map ? response.body['data'] : null;
      return (ok && data is Map) ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('AttendanceSummaryService: gagal memuat working-hours: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchTodayRaw() async {
    try {
      final response = await GetConnect().get('$_baseApiUrl/attendance/today', headers: await _authHeaders());
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('AttendanceSummaryService: gagal memuat /attendance/today: $e');
      return null;
    }
  }

  /// Record absensi hari ini (dari `records`), atau null kalau belum ada
  /// (belum check-in).
  Future<Map<String, dynamic>?> fetchToday() async {
    final data = await _fetchTodayRaw();
    final records = data?['records'];
    if (records is List && records.isNotEmpty && records.first is Map) {
      return Map<String, dynamic>.from(records.first as Map);
    }
    return null;
  }

  /// Jadwal shift hari ini (dari `shifts`) - dipakai AbsenCheckinController
  /// untuk menentukan pos yang benar-benar berlaku SEKARANG, bukan cuma
  /// pos pertama dari katalog `/posts?type=utama` yang tidak terikat
  /// jadwal sama sekali. List kosong kalau memang tidak ada shift
  /// terjadwal hari ini.
  Future<List<Map<String, dynamic>>> fetchShiftsToday() async {
    final data = await _fetchTodayRaw();
    final shifts = data?['shifts'];
    if (shifts is List) {
      return shifts.whereType<Map>().map((s) => Map<String, dynamic>.from(s)).toList();
    }
    return [];
  }

  static String formatJamMenit(num? totalMinutes) {
    if (totalMinutes == null) return '-';
    final total = totalMinutes.toInt();
    return '${total ~/ 60}j ${total % 60}m';
  }

  static const _bulanSingkat = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  static String formatSejak(String? isoDate) {
    final date = isoDate == null ? null : DateTime.tryParse(isoDate)?.toLocal();
    if (date == null) return '-';
    return 'Sejak ${_bulanSingkat[date.month]} ${date.year}';
  }

  static String _formatJam(String? isoDateTime) {
    final date = isoDateTime == null ? null : DateTime.tryParse(isoDateTime)?.toLocal();
    if (date == null) return '-';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatJamCheckIn(Map<String, dynamic>? todayRecord) => _formatJam(todayRecord?['checked_in_at']?.toString());

  static String formatJamCheckOut(Map<String, dynamic>? todayRecord) => _formatJam(todayRecord?['checked_out_at']?.toString());
}
