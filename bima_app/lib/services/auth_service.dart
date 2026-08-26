// Menyimpan sesi login (access token, refresh token, dan data user) secara
// lokal lewat SharedPreferences, diisi oleh login_controller.dart setelah
// POST /auth/login sukses dan dibersihkan oleh profile_saya_controller.dart
// saat logout.
//
// Checkbox "Ingat Saya" (lihat login_controller.dart) menentukan apakah
// sesi ini bertahan lintas cold-start: kalau dicentang, sesi tetap ada dan
// main.dart akan langsung ke halaman utama di buka berikutnya; kalau tidak,
// sesi tetap berlaku selama proses aplikasi ini masih hidup, tapi otomatis
// dihapus oleh clearSessionIfNotRemembered() di awal main() saat aplikasi
// dibuka lagi dari kondisi tertutup penuh — lihat main.dart.
//
// isLoggedIn() juga mengecek klaim `exp` di access_token (JWT) — kalau
// sudah kedaluwarsa, sesi otomatis dibersihkan dan dianggap logout.
//
// refreshToken() (POST /auth/refresh) sudah tersedia untuk menukar
// refresh_token dengan sesi baru, TAPI belum dipanggil otomatis di mana
// pun (belum ada auto-retry-on-401) — itu sengaja jadi task terpisah,
// begitu juga pemasangan header Authorization di pemanggilan API lain
// (absensi/patroli/tracking/register).
//
// validateSessionWithServer() (GET /auth/me) dipanggil main.dart saat app
// dibuka untuk menangkap token yang di-revoke di server walau klaim exp
// JWT-nya belum lewat. MODE OFFLINE-TOLERANT: kalau server tidak terjangkau
// sama sekali, sesi lokal tetap dipercaya — hanya 401 eksplisit dari server
// yang memaksa logout.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyRefreshExpiresAt = 'auth_refresh_expires_at';
  static const _keyUser = 'auth_user';
  static const _keyRememberMe = 'auth_remember_me';

  String get _baseUrl => dotenv.env['BASE_API_URL']!;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String refreshExpiresAt,
    required Map<String, dynamic> user,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyRefreshExpiresAt, refreshExpiresAt);
    await prefs.setString(_keyUser, jsonEncode(user));
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// True kalau ada access_token tersimpan DAN belum kedaluwarsa (dibaca
  /// dari klaim `exp` di JWT-nya). Kalau ternyata sudah kedaluwarsa, sesi
  /// ikut dibersihkan di sini supaya tidak nyangkut setengah-login.
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    final expiresAt = _decodeJwtExpiry(token);
    if (expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt)) {
      await clearSession();
      return false;
    }
    return true;
  }

  /// Baca klaim `exp` (Unix timestamp detik) dari access_token JWT tanpa
  /// perlu memverifikasi tanda tangannya — cukup untuk tahu kapan token
  /// ini kedaluwarsa di sisi klien. Null kalau token bukan JWT yang valid
  /// atau tidak punya klaim `exp` (dianggap tidak pernah kedaluwarsa).
  DateTime? _decodeJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  /// Dipanggil sekali di awal main() sebelum menentukan initial route.
  /// Kalau ada sesi tersimpan tapi login sebelumnya TIDAK mencentang
  /// "Ingat Saya", sesi itu hanya berlaku untuk satu kali buka aplikasi —
  /// dihapus di sini supaya cold-start berikutnya kembali minta login.
  Future<void> clearSessionIfNotRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyRefreshExpiresAt);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyRememberMe);
  }

  /// Beri tahu backend supaya token ini di-invalidate (POST /auth/logout,
  /// Return 204), lalu selalu bersihkan sesi lokal terlepas dari hasil
  /// panggilan itu — kalau request gagal (offline dsb.), pengguna tetap
  /// harus bisa keluar dari akunnya di HP-nya sendiri.
  Future<void> logout() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await GetConnect().post(
          '$_baseUrl/auth/logout',
          {},
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        debugPrint('AuthService: gagal memberi tahu server saat logout (diabaikan): $e');
      }
    }
    await clearSession();
  }

  /// GET /auth/me — validasi access_token ke server sekaligus menyegarkan
  /// data user tersimpan. True kalau sesi masih boleh dipakai.
  ///
  /// MODE OFFLINE-TOLERANT: kalau tidak dapat respons sama sekali dari
  /// server (tidak ada internet, timeout, dll), sesi lokal tetap dipercaya
  /// apa adanya (return sama dengan isLoggedIn() lokal) — pengguna tidak
  /// boleh "diusir" ke halaman login hanya karena sedang offline. Sesi
  /// HANYA dibersihkan kalau server secara eksplisit menjawab 401.
  Future<bool> validateSessionWithServer() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await GetConnect().get(
        '$_baseUrl/auth/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        await clearSession();
        return false;
      }

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        final data = response.body is Map ? response.body['data'] : null;
        final userMap = data is Map && data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : (data is Map && data['uuid'] != null ? Map<String, dynamic>.from(data) : null);
        if (userMap != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUser, jsonEncode(userMap));
        }
      }
      return true;
    } catch (e) {
      debugPrint('AuthService: gagal validasi /auth/me ke server, pakai sesi lokal (offline?): $e');
      return true;
    }
  }

  /// POST /auth/refresh — tukar refresh_token tersimpan dengan sesi baru
  /// (access_token, refresh_token, refresh_expires_at, user). Endpoint ini
  /// tidak menerima body — refresh_token dikirim lewat header Authorization
  /// (pola sama seperti /auth/logout).
  ///
  /// Melempar Exception kalau tidak ada refresh_token tersimpan atau
  /// panggilan gagal; sesi lama TIDAK diubah kalau gagal, supaya pemanggil
  /// bisa memutuskan sendiri langkah selanjutnya (mis. paksa login ulang).
  /// BELUM dipanggil otomatis di mana pun — lihat catatan di atas file ini.
  Future<void> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Tidak ada refresh token tersimpan.');
    }

    final response = await GetConnect().post(
      '$_baseUrl/auth/refresh',
      {},
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    final data = response.body is Map ? response.body['data'] as Map<String, dynamic>? : null;
    final user = data?['user'];

    if (!ok || data == null || user is! Map) {
      throw Exception('Gagal memperbarui sesi lewat refresh token (status ${response.statusCode}).');
    }

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

    await saveSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      refreshExpiresAt: data['refresh_expires_at'] as String,
      user: Map<String, dynamic>.from(user),
      rememberMe: rememberMe,
    );
  }
}
