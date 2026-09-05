// Ringkasan jam kerja & absensi hari ini — dipakai Beranda dan Profil
// Saya untuk kartu statistik durasi. Selalu fetch baru (TIDAK di-cache
// seperti SatpamProfileService) karena datanya berubah tiap kali
// check-in/check-out, beda dari identitas satpam yang jarang berubah.
//
// GET /attendance/working-hours -> { data: { today: {minutes,hours,
// shifts}, this_month: {...}, all_time: {...}, since } }
//
// GET /attendance/today -> { data: [...], meta: { date } } — LIST (bisa
// >1 kalau ada dua shift sehari, meski jarang); elemen pertama dipakai
// karena kartu ringkasan cuma menampilkan satu status. List kosong berarti
// belum ada absensi hari ini (belum check-in).

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

  /// Record absensi hari ini, atau null kalau belum ada (belum check-in).
  Future<Map<String, dynamic>?> fetchToday() async {
    try {
      final response = await GetConnect().get('$_baseApiUrl/attendance/today', headers: await _authHeaders());
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = response.body is Map ? response.body['data'] : null;
      if (ok && data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      return null;
    } catch (e) {
      debugPrint('AttendanceSummaryService: gagal memuat absensi hari ini: $e');
      return null;
    }
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
