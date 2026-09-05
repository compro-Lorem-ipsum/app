// Antrian lokal titik GPS (SQLite, tabel `gps_queue`) selama satu shift
// berlangsung. Seluruh titik satu sesi (bukan cuma yang "belum terkirim")
// dirangkai jadi satu polyline dan dikirim sebagai bagian body check-out —
// lihat TrackingService.buildCheckoutPolyline() — karena kontrak backend
// mengganti (replace) seluruh rute tersimpan setiap kali menerima polyline
// baru, bukan menambahkannya.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class GpsPoint {
  final int? id;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final String? absensiUuid;
  final bool synced;

  GpsPoint({
    this.id,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.absensiUuid,
    this.synced = false,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'lat': lat,
        'lng': lng,
        'recorded_at': recordedAt.toIso8601String(),
        'absensi_uuid': absensiUuid,
        'synced': synced ? 1 : 0,
      };

  factory GpsPoint.fromMap(Map<String, Object?> map) => GpsPoint(
        id: map['id'] as int?,
        lat: map['lat'] as double,
        lng: map['lng'] as double,
        recordedAt: DateTime.parse(map['recorded_at'] as String),
        absensiUuid: map['absensi_uuid'] as String?,
        synced: (map['synced'] as int) == 1,
      );
}

class QueueService {
  QueueService._internal();
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'gps_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE gps_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          recorded_at TEXT NOT NULL,
          absensi_uuid TEXT,
          synced INTEGER NOT NULL DEFAULT 0
        )
      '''),
    );
    return _db!;
  }

  /// Simpan satu titik GPS baru ke antrian lokal (belum synced).
  Future<int> enqueue(GpsPoint point) async {
    final db = await _database;
    return db.insert('gps_queue', point.toMap());
  }

  /// Semua titik satu sesi absensi (urut waktu) — dipakai baik untuk
  /// merangkai polyline check-out (TrackingService.buildCheckoutPolyline)
  /// maupun untuk debug map (TrackingService.exportDebugMap).
  Future<List<GpsPoint>> getAllForSession(String absensiUuid) async {
    final db = await _database;
    final rows = await db.query(
      'gps_queue',
      where: 'absensi_uuid = ?',
      whereArgs: [absensiUuid],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(GpsPoint.fromMap).toList();
  }

  /// Tempel `absensi_uuid` ke titik-titik yang belum punya, dipakai supaya
  /// titik yang telat terkirim tetap nyantol ke sesi absensi yang benar.
  Future<void> tagAbsensiUuid(String absensiUuid) async {
    final db = await _database;
    await db.update(
      'gps_queue',
      {'absensi_uuid': absensiUuid},
      where: 'synced = 0 AND absensi_uuid IS NULL',
    );
  }

  /// Kosongkan seluruh antrian lokal. Dipanggil dari TrackingService
  /// setelah check-out (dan polyline-nya) sukses terkirim ke server —
  /// lihat TrackingService.stopTracking.
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('gps_queue');
  }
}
