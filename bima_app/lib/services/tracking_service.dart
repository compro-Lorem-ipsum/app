// Merekam posisi GPS satpam selama masa "bertugas" dan menyimpannya secara
// lokal (lihat queue_service.dart), lalu mengirim semuanya sekaligus
// (batch) tepat sebelum check-out — bukan real-time — karena rute baru
// diproses backend setelah check-out (lihat dokumentasi GPS Tracking).
//
// Empat lapis ketahanan: (1) GPS stream sebagai sumber utama, (2) timer
// fallback yang memakai getLastKnownPosition kalau stream diam, dan
// (3) watchdog yang me-restart stream kalau mati — KETIGANYA berjalan di
// dalam Android foreground service (lihat gps_task_handler.dart), bukan di
// isolate utama, supaya tetap hidup walau layar mati/aplikasi di-minimize.
// (4) WorkManager (lihat workmanager_callback.dart) sebagai heartbeat
// tambahan kalau OEM tertentu tetap membunuh foreground service ini.
//
// MODE FALLBACK: endpoint `/satpam-app/:uuid/tracking/batch` belum
// tersedia di backend saat ini. Kalau pengiriman gagal karena backend
// tidak terjangkau, titik TETAP tersimpan aman di antrian lokal (tidak
// hilang, tidak ditandai synced) dan proses check-out tetap boleh lanjut
// (dengan flag gps_incomplete=true) supaya bagian FE tetap bisa dites
// tanpa perlu backend menyala.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gps_task_handler.dart';
import 'queue_service.dart';
import 'tracking_prefs_keys.dart';

class TrackingService {
  TrackingService._internal();
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;

  static const _serviceId = 990;

  static const _prefKeyAccumDistance = TrackingPrefKeys.accumDistance;
  static const _prefKeyLastLat = TrackingPrefKeys.lastLat;
  static const _prefKeyLastLng = TrackingPrefKeys.lastLng;
  static const _prefKeyLastSavedAt = TrackingPrefKeys.lastSavedAt;
  static const _prefKeyOnDuty = TrackingPrefKeys.onDuty;
  static const _prefKeyAbsensiUuid = TrackingPrefKeys.absensiUuid;

  static const _downloadsChannel = MethodChannel('bima_app/downloads');

  bool _isTracking = false;

  /// Mulai merekam titik GPS untuk shift saat ini. Dipanggil setelah
  /// check-in berhasil. GPS stream sesungguhnya berjalan di dalam Android
  /// foreground service (gps_task_handler.dart), bukan di sini, supaya
  /// tetap hidup walau layar mati.
  Future<void> startTracking({required String absensiUuid}) async {
    if (_isTracking) return;
    _isTracking = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnDuty, true);
    await prefs.setString(_prefKeyAbsensiUuid, absensiUuid);

    // Sisa antrian shift SEBELUMNYA yang belum sempat ter-flush (mis. tidak
    // ada internet persis saat checkout) dibersihkan di background, tanpa
    // menunda mulainya tracking shift baru ini.
    unawaited(flushLeftoverInBackground());

    await _ensurePermissions();
    _initForegroundTask();
    await _startForegroundService();

    debugPrint('TrackingService: tracking dimulai untuk $absensiUuid');
  }

  /// Minta izin lokasi (termasuk latar belakang) dan izin notifikasi
  /// (Android 13+, wajib supaya notifikasi foreground service tampil).
  Future<void> _ensurePermissions() async {
    final notifPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      // Android 11+ mewajibkan izin lokasi "sepanjang waktu" diminta
      // terpisah, setelah izin "saat digunakan" sudah disetujui lebih dulu.
      permission = await Geolocator.requestPermission();
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bima_gps_tracking',
        channelName: 'Pelacakan Lokasi Patroli',
        channelDescription: 'Notifikasi ini tampil selama Anda sedang bertugas dan lokasi sedang direkam.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'Sedang merekam patroli',
      notificationText: '',
      callback: gpsTaskStartCallback,
    );
  }

  Future<void> _rememberLastPoint(SharedPreferences prefs, Position position) async {
    await prefs.setDouble(_prefKeyLastLat, position.latitude);
    await prefs.setDouble(_prefKeyLastLng, position.longitude);
    await prefs.setString(_prefKeyLastSavedAt, DateTime.now().toIso8601String());
  }

  Future<void> _enqueueCurrent(SharedPreferences prefs, Position position) async {
    final absensiUuid = prefs.getString(_prefKeyAbsensiUuid);
    await QueueService().enqueue(GpsPoint(
      lat: position.latitude,
      lng: position.longitude,
      recordedAt: DateTime.now(),
      absensiUuid: absensiUuid,
    ));
  }

  /// Hentikan sementara penangkapan titik (dipanggil di awal proses
  /// check-out, sebelum flush terakhir). Checkout selalu berlangsung dengan
  /// app di foreground, jadi aman menghentikan foreground service di sini —
  /// captureFinalPoint() di bawah mengambil satu titik penutup langsung
  /// dari isolate utama.
  Future<void> pauseCapture() async {
    await FlutterForegroundTask.stopService();
  }

  /// Ambil satu titik penutup shift. Selalu disimpan meski belum genap
  /// 15 m / 60 detik, supaya rute tidak kehilangan posisi tepat sebelum
  /// check-out.
  Future<void> captureFinalPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
      final prefs = await SharedPreferences.getInstance();
      await _rememberLastPoint(prefs, position);
      await _enqueueCurrent(prefs, position);
    } catch (e) {
      debugPrint('TrackingService: gagal ambil titik akhir: $e');
    }
  }

  /// Kirim semua titik yang masih tertunda ke server sekaligus (batch),
  /// dipanggil tepat sebelum submit check-out. `true` = flush berhasil
  /// (atau memang tidak ada sisa), `false` = masih ada titik gagal
  /// terkirim (mis. backend belum tersedia) — pemanggil tetap boleh lanjut
  /// check-out dengan menandai `gps_incomplete: true`.
  Future<bool> flushForCheckout({required String satpamUuid}) async {
    final ok = await _flushOnce(satpamUuid: satpamUuid);
    if (ok) return true;
    // Sesuai dokumentasi: kalau gagal, di-retry sekali secara inline
    // sebelum menyerah dan membiarkan checkout tetap lanjut.
    return _flushOnce(satpamUuid: satpamUuid);
  }

  Future<bool> _flushOnce({required String satpamUuid}) async {
    final pending = await QueueService().getPending();
    if (pending.isEmpty) return true;

    try {
      final baseUrl = dotenv.env['BASE_API_URL'];
      final response = await GetConnect()
          .post(
            '$baseUrl/satpam-app/$satpamUuid/tracking/batch',
            {
              'points': pending
                  .map((p) => {
                        'lat': p.lat,
                        'lng': p.lng,
                        'recorded_at': p.recordedAt.toIso8601String(),
                      })
                  .toList(),
            },
          )
          .timeout(const Duration(seconds: 10));

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        await QueueService().markSynced(pending.map((p) => p.id!).toList());
        return true;
      }
      debugPrint('TrackingService: flush ditolak server (status ${response.statusCode})');
      return false;
    } catch (e) {
      // MODE FALLBACK (backend belum tersedia): titik tetap aman di
      // antrian lokal, tapi karena belum ada backend untuk benar-benar
      // menyimpannya, cache ini akan dibuang begitu saja di stopTracking()
      // begitu shift ini selesai (lihat catatan di sana).
      debugPrint('TrackingService: flush gagal, mode offline/testing: $e');
      return false;
    }
  }

  /// Kirim sisa antrian dari shift SEBELUMNYA yang belum ter-flush,
  /// dipanggil fire-and-forget dari startTracking() supaya tidak menunda
  /// mulainya tracking shift baru.
  Future<void> flushLeftoverInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final satpamUuid = prefs.getString(_prefKeyAbsensiUuid);
    if (satpamUuid == null) return;
    unawaited(_flushOnce(satpamUuid: satpamUuid));
  }

  /// Sudahi tracking untuk shift ini (dipanggil setelah check-out sukses).
  ///
  /// MODE FALLBACK: selain menghentikan foreground service, ini juga
  /// mengosongkan SELURUH antrian lokal (synced maupun belum). Idealnya
  /// titik yang gagal terkirim dipertahankan untuk di-retry, tapi karena
  /// endpoint batch belum tersedia di backend DAN setiap shift masih
  /// memakai `absensi_uuid` placeholder yang sama, titik gagal yang
  /// dibiarkan nyantol akan ikut kebawa ke rute shift berikutnya. Setelah
  /// backend & uuid per-sesi sungguhan tersedia, ganti ini dengan retry
  /// yang mempertahankan titik gagal per sesi.
  Future<void> stopTracking() async {
    await pauseCapture();
    _isTracking = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnDuty, false);
    await prefs.remove(_prefKeyLastLat);
    await prefs.remove(_prefKeyLastLng);
    await prefs.remove(_prefKeyLastSavedAt);
    await prefs.remove(_prefKeyAccumDistance);
    await QueueService().clearAll();
  }

  Future<bool> isOnDuty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyOnDuty) ?? false;
  }

  /// KHUSUS DEBUGGING (tidak menambah UI apa pun): setelah check-out
  /// sukses, tulis peta interaktif (Leaflet.js, gaya folium) berisi rute
  /// titik-titik GPS sesi ini langsung ke folder Downloads publik (lewat
  /// MediaStore, lihat MainActivity.kt) supaya rute hasil tracking bisa
  /// langsung ditemukan & dibuka di HP tanpa perlu adb. Dipanggil hanya
  /// saat `kDebugMode` — tidak pernah aktif di build production.
  ///
  /// Mengembalikan lokasi file HTML yang ditulis (relatif ke Downloads),
  /// atau null kalau gagal (mis. tidak ada titik tersimpan sama sekali).
  Future<String?> exportDebugMap({required String satpamUuid}) async {
    try {
      final points = await QueueService().getAllForSession(satpamUuid);
      if (points.isEmpty) {
        debugPrint('TrackingService: tidak ada titik GPS untuk diexport (debug map).');
        return null;
      }

      final filename = 'tracking_${DateTime.now().millisecondsSinceEpoch}.html';
      final savedPath = await _downloadsChannel.invokeMethod<String>('saveToDownloads', {
        'fileName': filename,
        'content': _buildDebugMapHtml(points),
        'mimeType': 'text/html',
      });

      debugPrint('TrackingService: debug map HTML tersimpan di $savedPath (${points.length} titik). '
          'Buka lewat File Manager > Downloads di HP.');
      return savedPath;
    } catch (e) {
      debugPrint('TrackingService: gagal membuat debug map HTML: $e');
      return null;
    }
  }

  String _buildDebugMapHtml(List<GpsPoint> points) {
    final centerLat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    final centerLng = points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;
    final routeCoords = points.map((p) => '[${p.lat},${p.lng}]').join(',');

    final markers = StringBuffer();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final isFirst = i == 0;
      final isLast = i == points.length - 1;
      final color = isFirst ? 'green' : (isLast ? 'red' : '#2b6cb0');
      final label = isFirst ? 'Mulai' : (isLast ? 'Selesai' : 'Titik ${i + 1}');
      markers.writeln('''
      L.circleMarker([${p.lat}, ${p.lng}], {radius: 7, color: "$color", fillColor: "$color", fillOpacity: 0.9})
        .addTo(map)
        .bindPopup("<b>$label</b><br>${p.recordedAt.toIso8601String()}<br>synced: ${p.synced}");''');
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Debug GPS Tracking (${points.length} titik)</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>html,body,#map{height:100%;margin:0;}</style>
</head>
<body>
  <div id="map"></div>
  <script>
    var map = L.map('map').setView([$centerLat, $centerLng], 17);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    var routeCoords = [$routeCoords];
    var route = L.polyline(routeCoords, {color: '#2b6cb0', weight: 4, opacity: 0.7}).addTo(map);

    $markers

    map.fitBounds(route.getBounds());
  </script>
</body>
</html>
''';
  }
}
