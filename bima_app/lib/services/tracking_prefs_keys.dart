// Kunci SharedPreferences yang dipakai bersama oleh tracking_service.dart
// (isolate utama), gps_task_handler.dart (isolate foreground service), dan
// workmanager_callback.dart (isolate WorkManager) — ketiganya adalah proses
// terpisah yang hanya bisa "ngobrol" lewat SharedPreferences/disk, jadi
// kuncinya harus persis sama di ketiganya.
class TrackingPrefKeys {
  static const accumDistance = 'tracking_accum_distance';
  static const lastLat = 'tracking_last_lat';
  static const lastLng = 'tracking_last_lng';
  static const lastSavedAt = 'tracking_last_saved_at';
  static const onDuty = 'tracking_on_duty';
  static const absensiUuid = 'tracking_absensi_uuid';
}
