// Menerima tap notifikasi Panic Alert (yang ditampilkan dari isolate
// WorkManager background, lihat workmanager_callback.dart) dan
// menavigasi ke halaman lokasi (/lokasi-panic) dengan data alert yang
// sama — sebelumnya tap notifikasi cuma membuka app ke Beranda tanpa
// tahu alert mana yang di-tap.
//
// Dua skenario tap yang beda caranya:
// 1. App masih hidup (foreground/background, belum ditutup total) — tap
//    langsung memicu `onDidReceiveNotificationResponse` di isolate utama
//    (Android membawa Activity yang sudah ada ke depan, jadi listener
//    yang didaftarkan sekali di main() ini yang menerima).
// 2. App sudah ditutup total — tap notifikasi yang meluncurkan proses
//    baru. Listener belum sempat terdaftar saat notifikasi di-tap, jadi
//    harus dicek manual lewat getNotificationAppLaunchDetails() di
//    main() SEBELUM initialRoute ditentukan, lalu dinavigasi setelah
//    frame pertama selesai (lihat main.dart).
//
// Plugin ini HARUS di-initialize terpisah di isolate utama (di sini)
// DAN di isolate WorkManager (workmanager_callback.dart) yang benar-benar
// memanggil .show() — keduanya isolate/engine terpisah yang cuma
// "ngobrol" lewat payload string yang ditempel ke notifikasi itu sendiri,
// bukan lewat state Dart bersama.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class PanicAlertNotificationService {
  PanicAlertNotificationService._internal();
  static final PanicAlertNotificationService _instance = PanicAlertNotificationService._internal();
  factory PanicAlertNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  /// Kalau app baru saja diluncurkan LEWAT tap notifikasi (app sebelumnya
  /// tertutup total), payload-nya ada di sini. Null kalau app dibuka
  /// normal (icon launcher, atau sudah berjalan).
  Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  static void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) navigateFromPayload(payload);
  }

  static void navigateFromPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      Get.toNamed('/lokasi-panic', arguments: {
        'satpamName': data['satpamName'],
        'nip': data['nip'],
        'mitra': data['mitra'],
        'time': data['time'],
        'latitude': (data['latitude'] as num?)?.toDouble(),
        'longitude': (data['longitude'] as num?)?.toDouble(),
      });
    } catch (e) {
      debugPrint('PanicAlertNotificationService: payload notifikasi tidak valid: $e');
    }
  }
}
