// Callback yang dijalankan WorkManager di background (isolate terpisah)
// sebagai lapisan ketahanan ke-4 GPS tracking: heartbeat berkala (tiap
// >=15 menit, minimum yang diizinkan Android) walau foreground service GPS
// sempat dimatikan OS. Lihat tracking_service.dart untuk 3 lapis lainnya.
//
// MODE FALLBACK: karena backend belum tersedia, callback ini didesain
// tidak pernah melempar error ke WorkManager (selalu return true) — kalau
// gagal terhubung ke server, titik tetap disimpan ke antrian lokal
// (queue_service.dart) untuk dicoba lagi nanti lewat tracking_service.dart.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'queue_service.dart';

const String kGpsHeartbeatTask = 'gps_heartbeat_task';

// Harus fungsi top-level (bukan method), dijalankan WorkManager di isolate
// terpisah dari isolate utama aplikasi.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kGpsHeartbeatTask) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final onDuty = prefs.getBool('tracking_on_duty') ?? false;
      if (!onDuty) return true;

      final absensiUuid = prefs.getString('tracking_absensi_uuid');

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return true;

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
    return true;
  });
}

/// Daftarkan heartbeat periodik. Dipanggil setelah check-in berhasil.
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

/// Batalkan heartbeat periodik. Dipanggil setelah check-out sukses.
Future<void> cancelBackgroundTracking() async {
  try {
    await Workmanager().cancelByUniqueName(kGpsHeartbeatTask);
  } catch (e) {
    debugPrint('WorkManager gagal dibatalkan (diabaikan): $e');
  }
}
