// Menyimpan sesi login (access token, refresh token, dan data user) secara
// lokal lewat SharedPreferences, diisi oleh login_controller.dart setelah
// POST /auth/login sukses dan dibersihkan oleh profile_saya_controller.dart
// saat logout.
//
// BELUM dipasang sebagai header Authorization di pemanggilan API lain
// (absensi/patroli/tracking/register) — itu sengaja jadi task terpisah.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyRefreshExpiresAt = 'auth_refresh_expires_at';
  static const _keyUser = 'auth_user';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String refreshExpiresAt,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyRefreshExpiresAt, refreshExpiresAt);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyRefreshExpiresAt);
    await prefs.remove(_keyUser);
  }
}
