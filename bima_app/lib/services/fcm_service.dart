// Push notification (Firebase Cloud Messaging).
//
// Backend menyimpan SATU token (fid) aktif per user (lihat POST
// /notifications/register) - device yang terakhir mendaftar itu yang
// menerima notifikasi. Satu-satunya notifikasi yang dikirim backend hari
// ini adalah keputusan registrasi (disetujui/ditolak), dengan payload
// `data: { type: "registration_decision", status }` TANPA blok
// `notification` - karena itu Android/iOS TIDAK otomatis menampilkan
// apa pun saat app di background/killed, harus dibuatkan local
// notification manual di sini (pola sama seperti heartbeat panic alert,
// lihat workmanager_callback.dart & panic_alert_notification_service.dart).
//
// Registrasi token PERTAMA KALI (sebelum akun disetujui admin) terjadi
// lewat POST /satpam/register langsung (lihat
// register_akun_part4_controller.dart) - satpam yang masih pending belum
// bisa login, jadi tidak bisa memanggil /notifications/register. Setelah
// login, endpoint itulah yang dipakai seterusnya, termasuk setiap kali
// token rotate (onTokenRefresh).
//
// firebaseMessagingBackgroundHandler HARUS fungsi top-level (bukan
// method) dan dijalankan Firebase di isolate terpisah dari isolate utama
// - isolate itu TIDAK menjalankan main(), jadi Firebase.initializeApp(),
// dotenv.load(), dan inisialisasi flutter_local_notifications harus
// diulang di sini juga (lewat _ensureLocalNotificationsInitialized, yang
// dijaga idempoten per-isolate lewat flag statis).
//
// GRACEFUL DEGRADATION: kalau android/app/google-services.json belum ada
// (lihat android/app/build.gradle.kts - plugin-nya hanya diterapkan kalau
// filenya ada), Firebase.initializeApp() melempar exception saat runtime.
// Semua pemanggilan Firebase di sini dibungkus try/catch dan dijaga lewat
// [_available] supaya fitur lain di app tetap jalan normal tanpa push
// notification, bukannya crash total - begitu file itu ditaruh, fitur ini
// otomatis aktif lagi di run berikutnya tanpa perlu ubah kode.

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('FcmService (background): Firebase belum dikonfigurasi (diabaikan): $e');
    return;
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('FcmService (background): gagal load .env (diabaikan): $e');
  }
  await FcmService._showLocalNotification(message);
}

class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _localNotificationsReady = false;

  /// False sampai [init] berhasil memastikan Firebase benar-benar
  /// terkonfigurasi (google-services.json ada) - dipakai method publik
  /// lain di kelas ini supaya tidak memanggil FirebaseMessaging API sama
  /// sekali kalau tidak, karena itu akan melempar exception.
  bool _available = false;

  String get _baseApiUrl => dotenv.env['BASE_API_URL']!;

  /// Sekali per isolate (dijaga [_localNotificationsReady]) - dipanggil
  /// baik dari isolate utama ([init]) maupun isolate FCM background
  /// ([firebaseMessagingBackgroundHandler]), supaya callback tap
  /// ([_handleNotificationTap]) tidak tertimpa kalau dipanggil berkali-kali.
  static Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsReady) return;
    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
    _localNotificationsReady = true;
  }

  /// Dipanggil sekali di main() terlepas dari status login - notifikasi
  /// keputusan registrasi bisa masuk SEBELUM satpam sempat login pertama
  /// kali. Kalau sesi login sudah ada (cold-start "Ingat Saya"), token
  /// saat ini juga langsung didaftarkan ulang di akhir fungsi ini.
  ///
  /// Firebase.initializeApp() & pendaftaran background handler ada di
  /// SINI (bukan main.dart) supaya satu try/catch ini menjaga semuanya -
  /// kalau google-services.json belum ada, seluruh fitur push notification
  /// nonaktif dengan rapi tanpa melempar apa pun ke pemanggil.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      await _ensureLocalNotificationsInitialized();

      // App masih hidup (foreground) saat pesan masuk.
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
      // App di background (belum ditutup total) lalu notifikasi FCM asli
      // di-tap untuk membuka app kembali.
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _handleDecisionTap());
      // Token bisa rotate kapan saja (reinstall, clear data, dsb) -
      // daftarkan ulang setiap kali itu terjadi.
      FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);

      // App diluncurkan LEWAT tap notifikasi FCM asli saat sebelumnya
      // tertutup total.
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleDecisionTap();

      _available = true;
    } catch (e) {
      debugPrint('FcmService: Firebase belum dikonfigurasi (google-services.json belum ada) - push notification dinonaktifkan sementara: $e');
      return;
    }

    await registerCurrentToken();
  }

  /// Ambil token FCM saat ini lalu daftarkan ke backend (no-op kalau belum
  /// login, atau kalau Firebase belum dikonfigurasi - dipakai juga oleh
  /// onTokenRefresh yang aktif terus-menerus).
  Future<void> registerCurrentToken() async {
    if (!_available) return;
    try {
      final fid = await FirebaseMessaging.instance.getToken();
      if (fid != null) await registerToken(fid);
    } catch (e) {
      debugPrint('FcmService: gagal ambil token FCM: $e');
    }
  }

  /// POST /notifications/register - owner diambil dari access_token,
  /// bukan dari body. Sengaja tidak melempar error kalau gagal (mis.
  /// offline); percobaan berikutnya (onTokenRefresh, atau init() saat app
  /// dibuka lagi) akan mencoba ulang.
  Future<void> registerToken(String fid) async {
    if (!_available) return;
    final accessToken = await AuthService().getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      await GetConnect().post(
        '$_baseApiUrl/notifications/register',
        {'fid': fid, 'platform': 'android'},
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint('FcmService: gagal mendaftarkan token FCM: $e');
    }
  }

  /// Dipakai saat langkah terakhir pendaftaran akun (POST /satpam/register,
  /// lihat register_akun_part4_controller.dart) - satpam yang masih
  /// pending belum bisa login jadi tidak bisa lewat [registerToken] biasa;
  /// endpoint itu menerima `fid`+`platform` langsung di body-nya sendiri.
  /// Null kalau token FCM belum tersedia (mis. Firebase belum dikonfigurasi,
  /// atau Play Services bermasalah) - pemanggil tetap boleh lanjut daftar
  /// tanpanya (fid+platform memang opsional di endpoint itu).
  Future<Map<String, String>?> currentDeviceFields() async {
    if (!_available) return null;
    try {
      final fid = await FirebaseMessaging.instance.getToken();
      if (fid == null) return null;
      return {'fid': fid, 'platform': 'android'};
    } catch (e) {
      debugPrint('FcmService: gagal ambil token FCM untuk pendaftaran: $e');
      return null;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.data['type'] != 'registration_decision') return;
    await _ensureLocalNotificationsInitialized();

    final status = (message.data['status'] ?? '').toString().toLowerCase();
    final isRejected = status.contains('reject') || status.contains('tolak');
    final title = isRejected ? 'Registrasi ditolak' : 'Registrasi disetujui';
    final body = isRejected
        ? 'Pendaftaran akun Anda ditolak oleh admin.'
        : 'Pendaftaran akun Anda disetujui. Silakan masuk untuk mulai bertugas.';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bima_notifications',
          'Notifikasi',
          channelDescription: 'Notifikasi umum dari BIMA (keputusan registrasi, dll)',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode({'type': 'registration_decision', 'status': status}),
    );
  }

  static void _handleNotificationTap(NotificationResponse response) => _handleDecisionTap();

  /// Satpam yang baru diputuskan admin (disetujui/ditolak) belum tentu
  /// masih login (biasanya malah belum pernah) - arahkan ke halaman Masuk
  /// supaya bisa login kalau disetujui, terlepas dari isi status.
  static void _handleDecisionTap() => Get.offAllNamed('/login');
}
