// Antrian lokal titik GPS (SQLite, tabel `gps_queue`) sebelum dikirim
// sekaligus (batch) ke server saat check-out. Setiap titik disimpan dulu
// di device dan baru ditandai `synced` setelah benar-benar terkirim —
// lihat tracking_service.dart untuk alur penangkapan & pengiriman batch-nya.

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

  /// Titik yang belum berhasil terkirim ke server, urut dari yang paling lama.
  Future<List<GpsPoint>> getPending() async {
    final db = await _database;
    final rows = await db.query('gps_queue', where: 'synced = 0', orderBy: 'recorded_at ASC');
    return rows.map(GpsPoint.fromMap).toList();
  }

  /// Semua titik (synced maupun belum) untuk satu sesi absensi, dipakai
  /// untuk keperluan debugging (lihat `TrackingService.exportDebugMap`) —
  /// bukan untuk proses pengiriman batch.
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

  /// Tandai sekumpulan titik sudah berhasil dikirim (server menerimanya).
  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update('gps_queue', {'synced': 1}, where: 'id IN ($placeholders)', whereArgs: ids);
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

  /// Kosongkan seluruh antrian lokal, synced maupun belum. Dipanggil setelah
  /// check-out (lihat TrackingService.stopTracking) — MODE FALLBACK: karena
  /// endpoint batch belum tersedia di backend, titik yang gagal terkirim
  /// tidak ada gunanya dipertahankan sampai sesi berikutnya (malah bikin
  /// rute sesi lama ikut kebawa ke sesi baru, karena keduanya masih memakai
  /// `absensi_uuid` placeholder yang sama).
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('gps_queue');
  }
}
