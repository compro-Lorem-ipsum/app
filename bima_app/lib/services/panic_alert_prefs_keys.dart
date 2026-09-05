// Kunci SharedPreferences untuk state Panic Alert yang dibagi antara
// isolate utama (panic_alert_polling_service.dart, polling cepat 15 detik
// selama app di foreground) dan isolate WorkManager
// (workmanager_callback.dart, heartbeat 15 menit selama app di
// background) — dua isolate terpisah yang cuma bisa "ngobrol" lewat
// SharedPreferences/disk, jadi kuncinya harus persis sama di keduanya.
class PanicAlertPrefKeys {
  /// Uuid alert yang statusnya sudah "diketahui" oleh salah satu isolate
  /// (foreground atau background) — siapa pun yang polling duluan menandai
  /// di sini, supaya yang satunya tidak menampilkan notifikasi duplikat
  /// untuk alert yang sama.
  static const seenAlertUuids = 'panic_alert_seen_uuids';
}
