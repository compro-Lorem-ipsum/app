// Status dokumen wajib satpam (KTP/BPJS/NPWP) dari GET /documents.
// Dipakai bareng oleh ProfileSayaController (banner "Lengkapi Dokumen"),
// LandingController (titik merah di avatar Beranda), dan
// UnggahBerkasController (detail per-slot) - satu sumber kebenaran supaya
// tidak triple-duplicate logic fetch + daftar tipe wajib.
//
// Bentuk record: { uuid, type, file: { uuid, status, view_url,
// download_url } | null, created_at }. `status` async - PENDING sampai
// Cloud Function selesai cek magic byte, lalu VALID atau INVALID. Dokumen
// dianggap "lengkap" hanya kalau KETIGA tipe wajib ada DAN statusnya VALID
// - yang masih PENDING/INVALID tidak dihitung supaya banner tidak salah
// bilang lengkap padahal salah satu berkasnya ditolak.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

class DocumentsService {
  DocumentsService._internal();
  static final DocumentsService _instance = DocumentsService._internal();
  factory DocumentsService() => _instance;

  static const requiredTypes = ['ktp', 'bpjs', 'npwp'];

  String get _baseApiUrl => dotenv.env['BASE_API_URL']!;

  /// Null kalau fetch gagal (network/envelope tidak sesuai) - dibedakan
  /// dari list kosong supaya pemanggil tahu ini "belum diketahui", bukan
  /// "memang belum ada dokumen".
  Future<List<Map<String, dynamic>>?> fetchAll() async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$_baseApiUrl/documents',
        headers: (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return null;
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('DocumentsService: gagal ambil daftar dokumen: $e');
      return null;
    }
  }

  /// Null kalau status belum diketahui (fetch gagal) - pemanggil sebaiknya
  /// menganggap ini seperti "belum lengkap" untuk sementara, bukan
  /// menyembunyikan indikatornya.
  Future<bool?> isComplete() async {
    final docs = await fetchAll();
    if (docs == null) return null;
    final validTypes = docs
        .where((doc) => (doc['file'] is Map ? (doc['file'] as Map)['status'] : null) == 'VALID')
        .map((doc) => doc['type']?.toString())
        .toSet();
    return requiredTypes.every(validTypes.contains);
  }
}
