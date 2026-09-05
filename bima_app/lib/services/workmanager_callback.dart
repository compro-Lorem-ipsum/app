// Callback yang dijalankan WorkManager di background (isolate terpisah)
// sebagai lapisan ketahanan ke-4 GPS tracking: heartbeat berkala (tiap
// >=15 menit, minimum yang diizinkan Android) walau foreground service GPS
// sempat dimatikan OS. Lihat tracking_service.dart untuk 3 lapis lainnya.
//
// File yang sama juga menjalankan heartbeat Panic Alert (>=15 menit) —
// satu-satunya cara satpam diberi tahu ada panic alert baru selagi app
// ditutup/di-background, karena proyek ini belum punya FCM (push
// notification asli). Dipilih WorkManager (bukan foreground service baru)
// justru supaya battery-friendly: 15 menit adalah interval minimum resmi
// Android untuk periodic WorkManager (App Standby/Doze tidak akan
// membangunkan app lebih sering dari itu), dan constraint
// `networkType: connected` memastikan radio jaringan tidak dibangunkan
// kalau memang sedang tidak ada koneksi. ATURAN: kalau app sedang dibuka
// (foreground), notifikasi tetap datang jauh lebih cepat lewat
// PanicAlertPollingService (polling 15 detik) — heartbeat WorkManager ini
// murni jaring pengaman untuk saat app tidak di foreground.
//
// MODE FALLBACK: karena backend belum tersedia, callback ini didesain
// tidak pernah melempar error ke WorkManager (selalu return true) — kalau
// gagal terhubung ke server, titik GPS tetap disimpan ke antrian lokal
// (queue_service.dart) untuk dicoba lagi nanti lewat tracking_service.dart;
// heartbeat panic alert yang gagal cukup dilewati, dicoba lagi di siklus
// berikutnya.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'auth_service.dart';
import 'panic_alert_prefs_keys.dart';
import 'queue_service.dart';
import 'tracking_prefs_keys.dart';

const String kGpsHeartbeatTask = 'gps_heartbeat_task';
const String kPanicAlertHeartbeatTask = 'panic_alert_heartbeat_task';

// Harus fungsi top-level (bukan method), dijalankan WorkManager di isolate
// terpisah dari isolate utama aplikasi — isolate ini TIDAK menjalankan
// main() sehingga dotenv belum pernah di-load di sini; wajib di-load
// ulang di setiap eksekusi sebelum baca BASE_API_URL (dipakai
// _runPanicAlertHeartbeat), kalau tidak dotenv.env melempar
// NotInitializedError.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('WorkManager: gagal load .env (diabaikan): $e');
    }

    if (task == kGpsHeartbeatTask) {
      await _runGpsHeartbeat();
    } else if (task == kPanicAlertHeartbeatTask) {
      await _runPanicAlertHeartbeat();
    }
    return true;
  });
}

Future<void> _runGpsHeartbeat() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final onDuty = prefs.getBool(TrackingPrefKeys.onDuty) ?? false;
    if (!onDuty) return;

    final absensiUuid = prefs.getString(TrackingPrefKeys.absensiUuid);

    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return;

    await QueueService().enqueue(GpsPoint(
      lat: position.latitude,
      lng: position.longitude,
      recordedAt: DateTime.now(),
      absensiUuid: absensiUuid,
    ));
    debugPrint('WorkManager heartbeat: titik tersimpan ke antrian lokal.');
  } catch (e) {
    // Diabaikan dengan sengaja: heartbeat background tidak boleh membuat
    // WorkManager menganggap jadwalnya gagal & mencoba retry paksa.
    debugPrint('WorkManager heartbeat gagal (diabaikan): $e');
  }
}

/// Cek GET /alerts/active sekali, tampilkan notifikasi sistem untuk alert
/// yang belum pernah "dilihat" (lihat PanicAlertPrefKeys.seenAlertUuids).
/// Bentuk field respons (satpam/client/lat/lng) belum dicontohkan persis
/// di dokumentasi API, dibaca defensif dengan beberapa kemungkinan nama.
Future<void> _runPanicAlertHeartbeat() async {
  try {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return;

    final baseUrl = dotenv.env['BASE_API_URL'];
    final response = await GetConnect().get(
      '$baseUrl/alerts/active',
      headers: {'Authorization': 'Bearer $token'},
    );

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
      if (!seen.contains(uuid)) newAlerts.add(item);
    }

    await prefs.setStringList(PanicAlertPrefKeys.seenAlertUuids, currentUuids.toList());
    if (newAlerts.isEmpty) return;

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    for (final alert in newAlerts) {
      final satpam = alert['satpam'] is Map ? Map<String, dynamic>.from(alert['satpam'] as Map) : null;
      final client = alert['client'] is Map ? Map<String, dynamic>.from(alert['client'] as Map) : null;
      final satpamName = (satpam?['nama'] ?? alert['nama'] ?? 'Satpam').toString();
      final mitra = (client?['nama'] ?? alert['mitra'] ?? '').toString();
      final uuid = (alert['uuid'] ?? '').toString();

      await notifications.show(
        uuid.hashCode,
        'Panic Alert Masuk',
        '$satpamName mengirim panic alert${mitra.isNotEmpty ? ' di $mitra' : ''}. Buka app untuk lihat lokasi.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bima_panic_alert',
            'Panic Alert',
            channelDescription: 'Notifikasi panic alert dari satpam lain',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('WorkManager panic alert heartbeat gagal (diabaikan): $e');
  }
}

/// Daftarkan heartbeat periodik GPS. Dipanggil setelah check-in berhasil.
/// Dibungkus try/catch supaya kalau WorkManager gagal diinisialisasi di
/// device tertentu, ini tidak sampai menjatuhkan alur check-in.
Future<void> initializeBackgroundTracking() async {
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      kGpsHeartbeatTask,
      kGpsHeartbeatTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  } catch (e) {
    debugPrint('WorkManager gagal diinisialisasi (diabaikan): $e');
  }
}

/// Batalkan heartbeat periodik GPS. Dipanggil setelah check-out sukses.
Future<void> cancelBackgroundTracking() async {
  try {
    await Workmanager().cancelByUniqueName(kGpsHeartbeatTask);
  } catch (e) {
    debugPrint('WorkManager gagal dibatalkan (diabaikan): $e');
  }
}

/// Daftarkan heartbeat periodik Panic Alert. Dipanggil setelah login
/// sukses (atau cold-start dengan sesi tersimpan) — TIDAK terikat status
/// on-duty seperti heartbeat GPS, karena panic alert relevan buat semua
/// satpam di client yang sama terlepas sedang bertugas atau tidak.
Future<void> initializePanicAlertHeartbeat() async {
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      kPanicAlertHeartbeatTask,
      kPanicAlertHeartbeatTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    debugPrint('WorkManager (panic alert) gagal diinisialisasi (diabaikan): $e');
  }
}

/// Batalkan heartbeat periodik Panic Alert. Dipanggil saat logout.
Future<void> cancelPanicAlertHeartbeat() async {
  try {
    await Workmanager().cancelByUniqueName(kPanicAlertHeartbeatTask);
  } catch (e) {
    debugPrint('WorkManager (panic alert) gagal dibatalkan (diabaikan): $e');
  }
}
