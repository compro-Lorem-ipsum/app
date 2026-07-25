// Merekam posisi GPS satpam selama masa "bertugas" dan menyimpannya secara
// lokal (lihat queue_service.dart), lalu mengirim semuanya sekaligus
// (batch) tepat sebelum check-out — bukan real-time — karena rute baru
// diproses backend setelah check-out (lihat dokumentasi GPS Tracking).
//
// Empat lapis ketahanan: (1) GPS stream sebagai sumber utama, (2) timer
// fallback yang memakai getLastKnownPosition kalau stream diam,
// (3) watchdog yang me-restart stream kalau mati, dan (4) WorkManager
// (lihat workmanager_callback.dart) sebagai heartbeat background.
//
// MODE FALLBACK: endpoint `/v1/satpam-app/:uuid/tracking/batch` belum
// tersedia di backend saat ini. Kalau pengiriman gagal karena backend
// tidak terjangkau, titik TETAP tersimpan aman di antrian lokal (tidak
// hilang, tidak ditandai synced) dan proses check-out tetap boleh lanjut
// (dengan flag gps_incomplete=true) supaya bagian FE tetap bisa dites
// tanpa perlu backend menyala.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'queue_service.dart';

class TrackingService {
  TrackingService._internal();
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;

  static const double _minDistanceMeters = 15.0;
  static const int _heartbeatSeconds = 60;
  static const Duration _watchdogInterval = Duration(minutes: 2);

  static const _prefKeyAccumDistance = 'tracking_accum_distance';
  static const _prefKeyLastLat = 'tracking_last_lat';
  static const _prefKeyLastLng = 'tracking_last_lng';
  static const _prefKeyLastSavedAt = 'tracking_last_saved_at';
  static const _prefKeyOnDuty = 'tracking_on_duty';
  static const _prefKeyAbsensiUuid = 'tracking_absensi_uuid';

  static const _downloadsChannel = MethodChannel('bima_app/downloads');

  StreamSubscription<Position>? _positionSub;
  Timer? _watchdogTimer;
  Timer? _fallbackTimer;
  DateTime? _lastEmitAt;
  bool _isTracking = false;

  /// Mulai merekam titik GPS untuk shift saat ini. Dipanggil setelah
  /// check-in berhasil.
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

    _startPositionStream();
    _startWatchdogAndFallback();

    debugPrint('TrackingService: tracking dimulai untuk $absensiUuid');
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _lastEmitAt = DateTime.now();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen(
      _onPosition,
      onError: (Object e) => debugPrint('TrackingService: gps stream error: $e'),
    );
  }

  void _startWatchdogAndFallback() {
    _watchdogTimer?.cancel();
    // Lapis 3: restart stream kalau sudah diam lebih dari satu periode
    // watchdog (mis. foreground service dibunuh OS pada beberapa HP).
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      final lastEmit = _lastEmitAt;
      if (lastEmit != null && DateTime.now().difference(lastEmit) > _watchdogInterval) {
        debugPrint('TrackingService: watchdog mendeteksi stream diam, restart...');
        _startPositionStream();
      }
    });

    _fallbackTimer?.cancel();
    // Lapis 2: kalau stream belum sempat emit satu titik pun dalam satu
    // periode heartbeat, pakai posisi terakhir yang diketahui agar antrian
    // tidak kosong.
    _fallbackTimer = Timer.periodic(const Duration(seconds: _heartbeatSeconds), (_) async {
      final lastEmit = _lastEmitAt;
      if (lastEmit != null && DateTime.now().difference(lastEmit) < const Duration(seconds: _heartbeatSeconds)) {
        return;
      }
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) await _onPosition(last);
      } catch (e) {
        debugPrint('TrackingService: fallback timer gagal: $e');
      }
    });
  }

  Future<void> _onPosition(Position position) async {
    _lastEmitAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final lastLat = prefs.getDouble(_prefKeyLastLat);
    final lastLng = prefs.getDouble(_prefKeyLastLng);
    final lastSavedAt = DateTime.tryParse(prefs.getString(_prefKeyLastSavedAt) ?? '');

    final isFirstPoint = lastLat == null || lastLng == null;
    final movedMeters =
        isFirstPoint ? 0.0 : Geolocator.distanceBetween(lastLat, lastLng, position.latitude, position.longitude);
    final secondsSinceLastSave =
        lastSavedAt == null ? _heartbeatSeconds + 1 : DateTime.now().difference(lastSavedAt).inSeconds;

    final shouldSave = isFirstPoint || movedMeters >= _minDistanceMeters || secondsSinceLastSave >= _heartbeatSeconds;
    if (!shouldSave) return;

    final accumulated = (prefs.getDouble(_prefKeyAccumDistance) ?? 0) + movedMeters;
    await prefs.setDouble(_prefKeyAccumDistance, accumulated);
    await _rememberLastPoint(prefs, position);
    await _enqueueCurrent(prefs, position);
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
  /// check-out, sebelum flush terakhir).
  Future<void> pauseCapture() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _watchdogTimer?.cancel();
    _fallbackTimer?.cancel();
  }

  /// Ambil satu titik penutup shift. Selalu disimpan meski belum genap
  /// 15 m / 60 detik, supaya rute tidak kehilangan posisi tepat sebelum
  /// check-out.
  Future<void> captureFinalPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 5));
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
            '$baseUrl/v1/satpam-app/$satpamUuid/tracking/batch',
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
      // antrian lokal untuk dicoba lagi nanti oleh retryLeftoverSync().
      debugPrint('TrackingService: flush gagal, mode offline/testing: $e');
      return false;
    }
  }

  /// Retry sisa antrian di background setelah check-out sukses, dengan
  /// exponential backoff + jitter (mulai 15 detik, maks 5 menit, sampai
  /// ~10 percobaan / ~10 menit total).
  Future<void> retryLeftoverSync({required String satpamUuid}) async {
    const maxAttempts = 10;
    const maxDelayMs = 5 * 60 * 1000;
    var delayMs = 15 * 1000;
    final random = Random();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final pending = await QueueService().getPending();
      if (pending.isEmpty) return;

      final jitterMs = random.nextInt(1000);
      await Future.delayed(Duration(milliseconds: delayMs + jitterMs));

      final ok = await _flushOnce(satpamUuid: satpamUuid);
      if (ok) return;

      delayMs = min(delayMs * 2, maxDelayMs);
    }
    debugPrint('TrackingService: retryLeftoverSync berhenti setelah $maxAttempts percobaan, '
        'masih ada sisa di antrian lokal (akan dicoba lagi saat shift berikutnya dimulai).');
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
  Future<void> stopTracking() async {
    await pauseCapture();
    _isTracking = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOnDuty, false);
    await prefs.remove(_prefKeyLastLat);
    await prefs.remove(_prefKeyLastLng);
    await prefs.remove(_prefKeyLastSavedAt);
    await prefs.remove(_prefKeyAccumDistance);
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
