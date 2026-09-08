// Merekam posisi GPS satpam selama masa "bertugas" dan menyimpannya secara
// lokal (lihat queue_service.dart). Rute dikirim ke server sebagai satu
// polyline ter-encode langsung di dalam body `POST /attendance/check-out`
// (field `polyline`, lihat absen_checkin_controller.dart) — bukan lewat
// panggilan terpisah, dan bukan real-time.
//
// PENTING — semantik REPLACE, bukan APPEND: kontrak backend menyimpan
// polyline yang dikirim APA ADANYA sebagai rute mentah (mengganti apa pun
// yang tersimpan sebelumnya), bukan menambahkannya ke rute lama. Karena
// itu, setiap kali rute dikirim harus berisi SELURUH titik shift ini sejak
// check-in — bukan cuma titik baru — supaya check-out yang di-retry
// (mis. gagal jaringan lalu dicoba lagi) tidak pernah kehilangan bagian
// rute. Ini juga kenapa tidak ada konsep "titik gagal ter-sync yang perlu
// di-retry terpisah": selama titiknya masih ada di antrian lokal, check-out
// berikutnya (kapan pun) otomatis mengirim ulang rute lengkap.
//
// Empat lapis ketahanan: (1) GPS stream sebagai sumber utama, (2) timer
// fallback yang memakai getLastKnownPosition kalau stream diam, dan
// (3) watchdog yang me-restart stream kalau mati — KETIGANYA berjalan di
// dalam Android foreground service (lihat gps_task_handler.dart), bukan di
// isolate utama, supaya tetap hidup walau layar mati/aplikasi di-minimize.
// (4) WorkManager (lihat workmanager_callback.dart) sebagai heartbeat
// tambahan kalau OEM tertentu tetap membunuh foreground service ini.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
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

  /// Rangkai SELURUH titik shift ini (sejak check-in, bukan cuma yang
  /// terbaru) menjadi satu string polyline ter-encode, untuk disisipkan
  /// langsung ke field `polyline` pada body `POST /attendance/check-out`.
  /// Null kalau tidak ada titik GPS sama sekali untuk shift ini — pemanggil
  /// cukup tidak menyertakan field `polyline` sama sekali di request-nya
  /// (mengosongkan field itu artinya "rute tersimpan dibiarkan apa
  /// adanya", BUKAN "hapus rute", sesuai dokumentasi).
  Future<String?> buildCheckoutPolyline() async {
    final prefs = await SharedPreferences.getInstance();
    final absensiUuid = prefs.getString(_prefKeyAbsensiUuid);
    if (absensiUuid == null) return null;

    final points = await QueueService().getAllForSession(absensiUuid);
    if (points.isEmpty) return null;

    return _encodePolyline(points);
  }

  /// Format Google Encoded Polyline Algorithm, presisi 5 desimal, sesuai
  /// kontrak `polyline` pada `POST /attendance/check-out` dan
  /// `POST /attendance/tracking`.
  String _encodePolyline(List<GpsPoint> points) {
    final buffer = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;

    for (final point in points) {
      final lat = (point.lat * 1e5).round();
      final lng = (point.lng * 1e5).round();
      _encodePolylineValue(lat - lastLat, buffer);
      _encodePolylineValue(lng - lastLng, buffer);
      lastLat = lat;
      lastLng = lng;
    }

    return buffer.toString();
  }

  void _encodePolylineValue(int value, StringBuffer buffer) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  /// Sudahi tracking untuk shift ini (dipanggil setelah check-out sukses,
  /// yaitu setelah polyline dari buildCheckoutPolyline() sudah terkirim
  /// sebagai bagian body check-out). Aman mengosongkan seluruh antrian
  /// lokal di sini karena rute lengkapnya sudah tersimpan di server —
  /// kalau check-out itu sendiri gagal, fungsi ini tidak pernah dipanggil,
  /// jadi titik GPS tidak ikut hilang dan otomatis ikut terkirim lagi
  /// (lengkap) di percobaan check-out berikutnya.
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

  /// Dipanggil saat logout (lihat ProfileSayaController.logout) - PAKSA
  /// hentikan tracking & buang SEMUA state lokalnya, termasuk antrian
  /// titik GPS yang belum sempat terkirim kalau shift ini ternyata belum
  /// di-checkout. Semua kunci di atas (`_prefKeyOnDuty`, `_prefKeyAbsensiUuid`,
  /// dkk) TIDAK dinamai per-akun - sengaja global di SharedPreferences -
  /// jadi kalau tidak dibersihkan di sini, akun lain yang login berikutnya
  /// di device yang sama akan mewarisi status "sedang bertugas" dan
  /// `absensi_uuid` milik akun sebelumnya (Beranda salah menampilkan
  /// tombol Check-out, dan check-out yang ditekan akun baru bisa terkirim
  /// memakai absensi_uuid akun lama).
  ///
  /// Beda dari [stopTracking] (dipanggil setelah checkout SUKSES, jadi
  /// aman menganggap semua titik sudah tersimpan di server) - di sini
  /// tidak ada jaminan itu, tapi mencegah kebocoran data lintas akun lebih
  /// penting daripada menyelamatkan titik GPS shift yang ditinggalkan
  /// begitu saja tanpa checkout.
  Future<void> resetForLogout() async {
    await pauseCapture();
    _isTracking = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnDuty, false);
    await prefs.remove(_prefKeyAbsensiUuid);
    await prefs.remove(_prefKeyLastLat);
    await prefs.remove(_prefKeyLastLng);
    await prefs.remove(_prefKeyLastSavedAt);
    await prefs.remove(_prefKeyAccumDistance);
    await QueueService().clearAll();
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
