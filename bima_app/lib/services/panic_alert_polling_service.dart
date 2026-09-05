// Menerima Panic Alert satpam lain lewat polling GET /alerts/active.
//
// Tidak ada push notification (FCM belum terpasang sama sekali di proyek
// ini), jadi satu-satunya cara tahu ada alert baru adalah polling. Dua
// lapis, mengikuti pola yang sama persis dengan 4-lapis GPS tracking:
//
// 1. FOREGROUND — Timer.periodic 15 detik di sini (isolate utama), untuk
//    respons cepat selama app sedang dibuka: langsung tampilkan dialog
//    "Panic Alert Masuk" dengan tombol lihat lokasi.
// 2. BACKGROUND — heartbeat WorkManager 15 menit (lihat
//    workmanager_callback.dart, initializePanicAlertHeartbeat), berjalan
//    di isolate terpisah walau app di-background/ditutup, cukup tampilkan
//    notifikasi sistem (tap notifikasi cuma membuka app, belum deep-link
//    langsung ke halaman lokasi — itu di luar cakupan perubahan ini).
//    15 menit dipilih karena itu interval MINIMUM resmi Android untuk
//    periodic WorkManager (App Standby/Doze tidak mengizinkan lebih
//    sering), jadi ini opsi paling battery-friendly yang tersedia untuk
//    polling background — satu-satunya cara lebih cepat dari itu adalah
//    push notification asli (FCM) atau foreground service permanen
//    (jauh lebih boros baterai, dan makna "foreground" jadi hilang).
//
// Dua isolate ini dikoordinasikan lewat SharedPreferences
// (PanicAlertPrefKeys.seenAlertUuids) supaya tidak dobel notifikasi untuk
// alert yang sama — siapa pun yang polling duluan (biasanya foreground,
// kalau app sedang dibuka) menandai alert itu "sudah dilihat".
//
// Alert yang sudah aktif pas polling PERTAMA kali (start() baru
// dipanggil, mis. baru login) dianggap "sudah diketahui" tanpa memicu
// notifikasi — supaya tidak muncul notifikasi untuk alert lama setiap
// kali app dibuka/login. Hanya alert yang baru muncul SETELAH itu yang
// memicu notifikasi.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'panic_alert_prefs_keys.dart';
import 'workmanager_callback.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class PanicAlertPollingService {
  PanicAlertPollingService._internal();
  static final PanicAlertPollingService _instance = PanicAlertPollingService._internal();
  factory PanicAlertPollingService() => _instance;

  static const _pollInterval = Duration(seconds: 15);

  Timer? _timer;
  bool _isFirstPoll = true;
  bool _isPolling = false;

  Future<void> start() async {
    if (_timer != null) return;

    _isFirstPoll = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PanicAlertPrefKeys.seenAlertUuids);

    // Notifikasi sistem (dipakai heartbeat background) butuh izin ini di
    // Android 13+ — dipakai bersama dengan izin notifikasi foreground
    // service GPS tracking (izin OS yang sama, sekali diberikan berlaku
    // untuk keduanya).
    final notifPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
    await initializePanicAlertHeartbeat();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PanicAlertPrefKeys.seenAlertUuids);
    await cancelPanicAlertHeartbeat();
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) return;

      final response = await GetConnect().get(
        '$_baseApiUrl/alerts/active',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        // Sesi sudah tidak valid — berhenti polling supaya tidak terus
        // memukul endpoint dengan token mati. Sesi akan dibersihkan lewat
        // jalur normal (mis. validateSessionWithServer di main.dart).
        await stop();
        return;
      }

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getStringList(PanicAlertPrefKeys.seenAlertUuids) ?? const []).toSet();

      final currentUuids = <String>{};
      final newAlerts = <Map<String, dynamic>>[];
      for (final raw in data.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        final uuid = (item['uuid'] ?? '').toString();
        if (uuid.isEmpty) continue;
        currentUuids.add(uuid);
        if (!seen.contains(uuid)) {
          newAlerts.add(item);
        }
      }

      await prefs.setStringList(PanicAlertPrefKeys.seenAlertUuids, currentUuids.toList());

      if (!_isFirstPoll) {
        for (final alert in newAlerts) {
          _showIncomingAlert(alert);
        }
      }
      _isFirstPoll = false;
    } catch (e) {
      debugPrint('PanicAlertPollingService: gagal polling /alerts/active: $e');
    } finally {
      _isPolling = false;
    }
  }

  /// Bentuk field respons alert (satpam/client/lat/lng/created_at) belum
  /// dicontohkan persis di dokumentasi — dibaca secara defensif dengan
  /// beberapa kemungkinan nama field.
  void _showIncomingAlert(Map<String, dynamic> alert) {
    final satpam = alert['satpam'] is Map ? Map<String, dynamic>.from(alert['satpam'] as Map) : null;
    final client = alert['client'] is Map ? Map<String, dynamic>.from(alert['client'] as Map) : null;

    final satpamName = (satpam?['nama'] ?? alert['nama'] ?? 'Satpam').toString();
    final nip = (satpam?['nip'] ?? alert['nip'] ?? '').toString();
    final mitra = (client?['nama'] ?? alert['mitra'] ?? '').toString();
    final lat = (alert['lat'] as num?)?.toDouble();
    final lng = (alert['lng'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse((alert['created_at'] ?? '').toString())?.toLocal();
    final time = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year} · ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '-';

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Panic Alert Masuk',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFA70202)),
        ),
        content: Text(
          '$satpamName${nip.isNotEmpty ? ' ($nip)' : ''} mengirim panic alert'
          '${mitra.isNotEmpty ? ' di $mitra' : ''}.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA70202)),
            onPressed: () {
              Get.back();
              Get.toNamed('/lokasi-panic', arguments: {
                'satpamName': satpamName,
                'nip': nip,
                'mitra': mitra,
                'time': time,
                'latitude': lat,
                'longitude': lng,
              });
            },
            child: const Text('Lihat Lokasi', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
