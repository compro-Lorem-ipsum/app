// Controller untuk halaman Unggah Berkas (KTP, BPJS, NPWP).
// Setiap dokumen diunggah lewat GCS signed POST policy (dua langkah, PERSIS
// sama seperti avatar registrasi — lihat register_akun_part4_controller.dart):
// (1) POST /documents/upload-url minta link upload, (2) POST file langsung
// ke bucket GCS pakai field-field yang dikembalikan, (3) POST /documents/
// menyimpan referensinya di backend dengan `object_uuid` hasil langkah 1.
// Semua endpoint /documents/* butuh header Authorization Bearer token.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../services/auth_service.dart';
import '../../widgets/success_screen.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class DocumentSlot {
  final String key;
  final String title;
  final String subtitle;
  bool uploaded;
  String? documentUuid;
  String? fileName;
  String? fileSize;
  String? filePath;

  DocumentSlot({
    required this.key,
    required this.title,
    required this.subtitle,
    this.uploaded = false,
    this.documentUuid,
    this.fileName,
    this.fileSize,
    this.filePath,
  });

  bool get isPdf => fileName?.toLowerCase().endsWith('.pdf') ?? false;
}

class UnggahBerkasController extends GetxController {
  final slots = <DocumentSlot>[
    DocumentSlot(key: 'ktp', title: 'KTP', subtitle: 'KTP Yang Masih Berlaku'),
    DocumentSlot(key: 'bpjs', title: 'BPJS', subtitle: 'BPJS Kesehatan / Ketenagakerjaan'),
    DocumentSlot(key: 'npwp', title: 'NPWP', subtitle: 'Nomor Pokok Wajib Pajak'),
  ].obs;

  /// Key slot yang sedang diproses (upload/hapus) — dipakai untuk
  /// menonaktifkan tombol slot itu saja selama network call berjalan.
  final processingKey = Rxn<String>();

  int get uploadedCount => slots.where((s) => s.uploaded).length;

  bool get isComplete => uploadedCount == slots.length;

  @override
  void onInit() {
    super.onInit();
    _fetchExistingDocuments();
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await AuthService().getAccessToken();
    return token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {};
  }

  Future<void> _fetchExistingDocuments() async {
    try {
      final response = await GetConnect().get('$BASE_API_URL/documents/', headers: await _authHeader());
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      if (data is! List) return;

      for (final doc in data.whereType<Map>()) {
        final type = doc['type']?.toString();
        DocumentSlot? slot;
        for (final s in slots) {
          if (s.key == type) {
            slot = s;
            break;
          }
        }
        if (slot == null) continue;

        slot.uploaded = true;
        slot.documentUuid = doc['uuid']?.toString();
        final path = doc['document_path']?.toString() ?? '';
        slot.fileName = path.isEmpty ? null : path.split('/').last;
      }
      slots.refresh();
    } catch (e) {
      debugPrint('UnggahBerkasController: gagal ambil dokumen tersimpan: $e');
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> upload(DocumentSlot slot) async {
    if (processingKey.value != null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    if (picked.path == null) return;

    processingKey.value = slot.key;
    try {
      // Langkah 1: minta upload-link.
      final linkRes = await GetConnect().post('$BASE_API_URL/documents/upload-url', {}, headers: await _authHeader());
      final linkOk = linkRes.statusCode != null && linkRes.statusCode! >= 200 && linkRes.statusCode! < 300;
      final linkData = linkOk && linkRes.body is Map ? linkRes.body['data'] as Map<String, dynamic>? : null;
      if (linkData == null) {
        _showError('Gagal Mengunggah', 'Tidak dapat memulai proses unggah dokumen, coba lagi.');
        return;
      }

      final objectUuid = linkData['object_uuid'] as String;
      final uploadUrl = linkData['upload_url'] as String;
      final fields = Map<String, dynamic>.from(linkData['fields'] as Map);
      final contentType = (linkData['content_type'] as String?) ?? fields['Content-Type'] as String? ?? 'application/octet-stream';

      // Langkah 2: upload file langsung ke GCS. Field-field HARUS ditulis
      // sebelum bagian file — dijamin http.MultipartRequest (fields
      // diserialisasi dulu, baru files), lihat catatan yang sama di
      // register_akun_part4_controller.dart.
      final uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields.addAll(fields.map((key, value) => MapEntry(key, value.toString())))
        ..files.add(await http.MultipartFile.fromPath('file', picked.path!, contentType: MediaType.parse(contentType)));

      final uploadResponse = await uploadRequest.send();
      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        _showError('Gagal Mengunggah', 'Gagal mengunggah file (status ${uploadResponse.statusCode}).');
        return;
      }

      // Langkah 3: simpan referensinya di backend.
      final saveHeaders = await _authHeader();
      saveHeaders['Content-Type'] = 'application/json';
      final saveResponse = await GetConnect().post(
        '$BASE_API_URL/documents/',
        {'type': slot.key, 'object_uuid': objectUuid},
        headers: saveHeaders,
      );
      final saveOk = saveResponse.statusCode != null && saveResponse.statusCode! >= 200 && saveResponse.statusCode! < 300;
      if (!saveOk) {
        _showDocumentError(saveResponse.statusCode, saveResponse.body);
        return;
      }

      slot.uploaded = true;
      slot.filePath = picked.path;
      slot.fileName = picked.name;
      slot.fileSize = _formatFileSize(picked.size);
      slots.refresh();

      // Sinkronkan documentUuid dari backend (dibutuhkan untuk hapus nanti).
      await _fetchExistingDocuments();
    } catch (e) {
      debugPrint('UnggahBerkasController: gagal unggah dokumen ${slot.key}: $e');
      _showError('Gagal Mengunggah', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      processingKey.value = null;
    }
  }

  void _showDocumentError(int? statusCode, dynamic body) {
    final error = body is Map ? body['error'] : null;
    final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();
    switch (statusCode) {
      case 400:
        _showError('Format File Tidak Didukung', rawMessage ?? 'Gunakan file JPG atau PDF.');
        return;
      case 202:
        _showError('Tipe Dokumen Tidak Valid', rawMessage ?? 'Tipe dokumen tidak dikenali.');
        return;
      default:
        _showError('Gagal Mengunggah', rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  Future<void> remove(DocumentSlot slot) async {
    if (processingKey.value != null) return;

    final uuid = slot.documentUuid;
    if (uuid == null) {
      // Belum sempat tersinkron ke server (mis. jaringan bermasalah pas
      // upload tadi) — cukup bersihkan state lokal.
      _clearSlotLocally(slot);
      return;
    }

    processingKey.value = slot.key;
    try {
      final response = await GetConnect().delete('$BASE_API_URL/documents/$uuid', headers: await _authHeader());
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (!ok) {
        _showError('Gagal Menghapus', 'Tidak dapat menghapus dokumen, coba lagi.');
        return;
      }
      _clearSlotLocally(slot);
    } catch (e) {
      debugPrint('UnggahBerkasController: gagal hapus dokumen ${slot.key}: $e');
      _showError('Gagal Menghapus', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      processingKey.value = null;
    }
  }

  void _clearSlotLocally(DocumentSlot slot) {
    slot.uploaded = false;
    slot.documentUuid = null;
    slot.fileName = null;
    slot.fileSize = null;
    slot.filePath = null;
    slots.refresh();
  }

  void submit() {
    if (!isComplete) return;
    Get.to(() => SuccessScreen(
          title: 'Behasil',
          subtitle: 'Berkas Anda berhasil di Unggah',
          buttonLabel: 'Kembali ke Beranda',
          buttonWidth: 316,
          buttonHeight: 60,
          buttonBorderRadius: 40,
          buttonFontSize: 20,
          onButtonPressed: () => Get.offAllNamed('/'),
        ));
  }
}
