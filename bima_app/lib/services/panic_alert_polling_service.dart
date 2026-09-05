// Menerima Panic Alert satpam lain lewat polling GET /alerts/active.
//
// Tidak ada push notification (FCM belum terpasang sama sekali di proyek
// ini — lihat catatan di README/laporan status untuk detail kenapa),
// jadi satu-satunya cara tahu ada alert baru selama app dibuka adalah
// polling berkala. Endpoint ini sengaja "tiny & unpaginated" menurut
// dokumentasi ("since active alerts are a handful of rows by
// definition"), jadi aman dipoll tiap beberapa detik.
//
// KETERBATASAN YANG DISADARI: ini polling foreground-only lewat
// Timer.periodic di isolate utama — TIDAK berjalan saat app di-background/
// ditutup (beda dengan GPS tracking yang punya foreground service
// terpisah). Satpam hanya diberi tahu soal alert baru selama app sedang
// dibuka di layar depan. Notifikasi walau app tertutup baru mungkin
// lewat FCM asli.
//
// Alert yang sudah pernah "dilihat" (uuid-nya sudah tercatat) tidak
// memicu dialog lagi di siklus polling berikutnya — termasuk alert yang
// SUDAH aktif pas polling pertama kali dimulai (mis. baru login), supaya
// tidak memunculkan dialog untuk alert lama setiap kali app dibuka.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class PanicAlertPollingService {
  PanicAlertPollingService._internal();
  static final PanicAlertPollingService _instance = PanicAlertPollingService._internal();
  factory PanicAlertPollingService() => _instance;

  static const _pollInterval = Duration(seconds: 15);

  Timer? _timer;
  final Set<String> _seenAlertUuids = {};
  bool _isFirstPoll = true;
  bool _isPolling = false;

  void start() {
    if (_timer != null) return;
    _isFirstPoll = true;
    _seenAlertUuids.clear();
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _seenAlertUuids.clear();
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) return;

      final response = await GetConnect().get(
        '$_baseApiUrl/alerts/active',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        // Sesi sudah tidak valid — berhenti polling supaya tidak terus
        // memukul endpoint dengan token mati. Sesi akan dibersihkan lewat
        // jalur normal (mis. validateSessionWithServer di main.dart).
        stop();
        return;
      }

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return;

      final currentUuids = <String>{};
      final newAlerts = <Map<String, dynamic>>[];
      for (final raw in data.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        final uuid = (item['uuid'] ?? '').toString();
        if (uuid.isEmpty) continue;
        currentUuids.add(uuid);
        if (!_seenAlertUuids.contains(uuid)) {
          newAlerts.add(item);
        }
      }

      _seenAlertUuids
        ..clear()
        ..addAll(currentUuids);

      if (!_isFirstPoll) {
        for (final alert in newAlerts) {
          _showIncomingAlert(alert);
        }
      }
      _isFirstPoll = false;
    } catch (e) {
      debugPrint('PanicAlertPollingService: gagal polling /alerts/active: $e');
    } finally {
      _isPolling = false;
    }
  }

  /// Bentuk field respons alert (satpam/client/lat/lng/created_at) belum
  /// dicontohkan persis di dokumentasi — dibaca secara defensif dengan
  /// beberapa kemungkinan nama field.
  void _showIncomingAlert(Map<String, dynamic> alert) {
    final satpam = alert['satpam'] is Map ? Map<String, dynamic>.from(alert['satpam'] as Map) : null;
    final client = alert['client'] is Map ? Map<String, dynamic>.from(alert['client'] as Map) : null;

    final satpamName = (satpam?['nama'] ?? alert['nama'] ?? 'Satpam').toString();
    final nip = (satpam?['nip'] ?? alert['nip'] ?? '').toString();
    final mitra = (client?['nama'] ?? alert['mitra'] ?? '').toString();
    final lat = (alert['lat'] as num?)?.toDouble();
    final lng = (alert['lng'] as num?)?.toDouble();
    final createdAt = DateTime.tryParse((alert['created_at'] ?? '').toString())?.toLocal();
    final time = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year} · ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '-';

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Panic Alert Masuk',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFA70202)),
        ),
        content: Text(
          '$satpamName${nip.isNotEmpty ? ' ($nip)' : ''} mengirim panic alert'
          '${mitra.isNotEmpty ? ' di $mitra' : ''}.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA70202)),
            onPressed: () {
              Get.back();
              Get.toNamed('/lokasi-panic', arguments: {
                'satpamName': satpamName,
                'nip': nip,
                'mitra': mitra,
                'time': time,
                'latitude': lat,
                'longitude': lng,
              });
            },
            child: const Text('Lihat Lokasi', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
