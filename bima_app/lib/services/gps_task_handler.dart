// TaskHandler yang dijalankan di dalam Android foreground service (lihat
// tracking_service.dart untuk orkestrasi start/stop-nya dari isolate utama).
// Ini FlutterEngine + isolate TERPISAH dari aplikasi utama, dan itulah
// intinya: selama notifikasi foreground service ini tampil, Android TIDAK
// membekukan isolate ini walau layar mati atau aplikasi di-minimize/di-swipe
// — beda dengan stream GPS biasa yang otomatis berhenti begitu proses utama
// dibekukan OS (Doze / App Standby).
//
// Tiga lapis pertama dari 4 lapis ketahanan GPS tracking berjalan di sini:
// (1) GPS stream sebagai sumber utama, (2) timer fallback yang memakai
// getLastKnownPosition kalau stream diam, (3) watchdog yang me-restart
// stream kalau mati. Lapis ke-4 (WorkManager heartbeat) tetap ada di
// workmanager_callback.dart sebagai jaring pengaman tambahan kalau OEM
// tertentu (Xiaomi/Oppo/Vivo/dll) tetap membunuh foreground service ini.

import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'queue_service.dart';
import 'tracking_prefs_keys.dart';

// Harus fungsi top-level (bukan method), dipanggil plugin untuk membuat
// FlutterEngine baru khusus foreground service ini.
@pragma('vm:entry-point')
void gpsTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

class GpsTaskHandler extends TaskHandler {
  static const double _minDistanceMeters = 15.0;
  static const int _heartbeatSeconds = 60;
  static const Duration _watchdogInterval = Duration(minutes: 2);

  StreamSubscription<Position>? _positionSub;
  Timer? _watchdogTimer;
  Timer? _fallbackTimer;
  DateTime? _lastEmitAt;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startPositionStream();

    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      final lastEmit = _lastEmitAt;
      if (lastEmit != null && DateTime.now().difference(lastEmit) > _watchdogInterval) {
        _startPositionStream();
      }
    });

    _fallbackTimer = Timer.periodic(const Duration(seconds: _heartbeatSeconds), (_) async {
      final lastEmit = _lastEmitAt;
      if (lastEmit != null && DateTime.now().difference(lastEmit) < const Duration(seconds: _heartbeatSeconds)) {
        return;
      }
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) await _onPosition(last);
      } catch (_) {
        // Diabaikan: akan dicoba lagi di periode heartbeat berikutnya.
      }
    });
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _lastEmitAt = DateTime.now();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen(_onPosition, onError: (_) {});
  }

  Future<void> _onPosition(Position position) async {
    _lastEmitAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    // Bisa saja stream lama masih emit sebentar tepat setelah checkout
    // memanggil stopTracking() sebelum service benar-benar berhenti.
    if (!(prefs.getBool(TrackingPrefKeys.onDuty) ?? false)) return;

    final lastLat = prefs.getDouble(TrackingPrefKeys.lastLat);
    final lastLng = prefs.getDouble(TrackingPrefKeys.lastLng);
    final lastSavedAt = DateTime.tryParse(prefs.getString(TrackingPrefKeys.lastSavedAt) ?? '');

    final isFirstPoint = lastLat == null || lastLng == null;
    final movedMeters =
        isFirstPoint ? 0.0 : Geolocator.distanceBetween(lastLat, lastLng, position.latitude, position.longitude);
    final secondsSinceLastSave =
        lastSavedAt == null ? _heartbeatSeconds + 1 : DateTime.now().difference(lastSavedAt).inSeconds;

    final shouldSave = isFirstPoint || movedMeters >= _minDistanceMeters || secondsSinceLastSave >= _heartbeatSeconds;
    if (!shouldSave) return;

    final accumulated = (prefs.getDouble(TrackingPrefKeys.accumDistance) ?? 0) + movedMeters;
    await prefs.setDouble(TrackingPrefKeys.accumDistance, accumulated);
    await prefs.setDouble(TrackingPrefKeys.lastLat, position.latitude);
    await prefs.setDouble(TrackingPrefKeys.lastLng, position.longitude);
    await prefs.setString(TrackingPrefKeys.lastSavedAt, DateTime.now().toIso8601String());

    final absensiUuid = prefs.getString(TrackingPrefKeys.absensiUuid);
    await QueueService().enqueue(GpsPoint(
      lat: position.latitude,
      lng: position.longitude,
      recordedAt: DateTime.now(),
      absensiUuid: absensiUuid,
    ));
  }

  // Tidak dipakai: seluruh siklus GPS diatur sendiri lewat stream + timer di
  // atas (lihat ForegroundTaskEventAction.nothing() di tracking_service.dart).
  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSub?.cancel();
    _watchdogTimer?.cancel();
    _fallbackTimer?.cancel();
  }
}
