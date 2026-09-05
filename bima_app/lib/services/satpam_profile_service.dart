// Cache singleton untuk data profil satpam (GET /satpam/me) — dipakai
// bersama oleh banyak halaman (Beranda, Check-in/out, Panic Alert, Profil
// Saya) supaya nama/nip/jabatan/mitra yang sama tampil konsisten tanpa
// masing-masing halaman fetch sendiri-sendiri dari nol.
//
// Response: { nama, nip, email, jabatan, nrg, gender, asal_daerah,
// client, date_assigned, kontak_utama }.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class SatpamProfileService {
  SatpamProfileService._internal();
  static final SatpamProfileService _instance = SatpamProfileService._internal();
  factory SatpamProfileService() => _instance;

  Map<String, dynamic>? _cached;
  Future<Map<String, dynamic>?>? _inFlight;

  /// Ambil profil satpam. Hasil di-cache di memori untuk sesi berjalan —
  /// panggilan berikutnya (dari halaman mana pun) langsung memakai cache
  /// tanpa fetch ulang, kecuali `forceRefresh: true` (dipakai halaman
  /// Profil Saya supaya selalu menampilkan data terbaru).
  Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) {
    if (!forceRefresh && _cached != null) return Future.value(_cached);
    if (_inFlight != null) return _inFlight!;

    final future = _fetch();
    _inFlight = future;
    return future;
  }

  Future<Map<String, dynamic>?> _fetch() async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$_baseApiUrl/satpam/me',
        headers: (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = response.body is Map ? response.body['data'] : null;
      if (ok && data is Map) {
        _cached = Map<String, dynamic>.from(data);
      }
      return _cached;
    } catch (e) {
      debugPrint('SatpamProfileService: gagal memuat profil: $e');
      return _cached;
    } finally {
      _inFlight = null;
    }
  }

  /// Buang cache — dipanggil saat logout supaya sesi berikutnya (akun
  /// lain di device yang sama) tidak sempat melihat data satpam
  /// sebelumnya sebelum fetch ulang selesai.
  void clear() {
    _cached = null;
    _inFlight = null;
  }
}
