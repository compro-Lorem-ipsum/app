// Controller untuk halaman Laporan Patroli.
//
// Sebelumnya controller ini dibangun terhadap kontrak yang sudah usang:
// - "Nama Personel" diambil dari GET /patroli/options lalu ambil item
//   pertama sebagai asumsi "satpam yang login" — sekarang dibaca langsung
//   dari sesi login (AuthService), tanpa fetch tambahan.
// - Pos diambil dari GET /patroli/options/:satpamUuid — endpoint yang
//   benar adalah GET /posts?type=jaga (satpam hanya melihat pos milik
//   client tempatnya ditugaskan).
// - Upload foto memakai PUT mentah ke "upload_urls" batch — kontrak yang
//   didokumentasikan adalah upload 2-langkah PER FOTO (POST
//   /patrols/upload-url -> object_uuid, lalu POST multipart ke GCS,
//   fields dulu baru file — sama seperti upload avatar/selfie absensi),
//   dan submit akhir mengirim `object_uuids` (bukan `filenames`).
// - Body submit memakai `satpam_uuid`/`status_lokasi`/`keterangan` yang
//   tidak ada di kontrak — yang benar `pos_uuid`, `status` (persis
//   `aman`/`tidak aman`), `description`.
// - Error dibaca dari `error.code` (NOT_ON_DUTY, POS_NOT_JAGA,
//   OUTSIDE_POS_RADIUS), bukan lagi menebak dari potongan teks pesan.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../services/auth_service.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class ReportPatroliController extends GetxController {
  static const _statusToApi = {'Aman': 'aman', 'Tidak Aman': 'tidak aman'};

  // ===== STATE =====
  var listPos = <dynamic>[].obs;

  // Nama personel yang sedang login, dibaca dari sesi (bukan fetch/pilihan manual).
  var personnelName = ''.obs;
  var selectedPos = ''.obs;
  var status = ''.obs;
  var notes = ''.obs;

  final notesController = TextEditingController();

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  // Path file lokal (4 foto) — bukan base64, cukup path untuk MultipartFile.
  var photos = List<String>.filled(4, "").obs;

  var isLoading = false.obs;
  var loadingMessage = ''.obs;

  var resultData = Rxn<Map<String, dynamic>>();
  var alertMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPersonnel();
    fetchPos();
    getGPS();
    notesController.addListener(() {
      notes.value = notesController.text;
    });
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  Future<Map<String, String>?> _authHeaders({bool json = false}) async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return json ? {'Content-Type': 'application/json'} : null;
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> _loadPersonnel() async {
    final user = await AuthService().getUser();
    personnelName.value = (user?['nama'] as String?) ?? '';
  }

  // ===== GPS =====
  Future<void> getGPS() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = pos.latitude;
      longitude.value = pos.longitude;
    } catch (_) {}
  }

  Future<void> goToCamera(int index) async {
    final result = await Get.toNamed(
      '/take-photo-patroli',
      arguments: {
        'index': index,
        'photos': photos,
      },
    );

    if (result != null && result is String) {
      photos[index] = result;
      photos.refresh();
    }
  }

  // ===== POS (GET /posts?type=jaga) =====
  Future<void> fetchPos() async {
    selectedPos.value = '';
    listPos.clear();

    try {
      final res = await GetConnect().get(
        '$BASE_API_URL/posts',
        query: {'type': 'jaga'},
        headers: await _authHeaders(),
      );
      final data = res.body is Map ? res.body['data'] : null;
      if (data is List) {
        listPos.value = data;
      }
    } catch (e) {
      debugPrint('ReportPatroliController: gagal ambil daftar pos: $e');
    }
  }

  // ===== PHOTO RESULT FROM CAMERA =====
  void setPhoto(int index, String path) {
    photos[index] = path;
    photos.refresh();
  }

  /// Upload satu foto lewat kontrak 2-langkah: POST /patrols/upload-url
  /// untuk reservasi object, lalu POST multipart ke GCS (fields dulu,
  /// file terakhir). Mengembalikan object_uuid untuk disertakan di body
  /// POST /patrols.
  Future<String> _uploadPhotoAndGetObjectUuid(String path) async {
    final linkRes = await GetConnect().post(
      '$BASE_API_URL/patrols/upload-url',
      {'ext': 'jpg'},
      headers: await _authHeaders(json: true),
    );
    final linkOk = linkRes.statusCode != null && linkRes.statusCode! >= 200 && linkRes.statusCode! < 300;
    final linkData = linkRes.body is Map ? linkRes.body['data'] as Map<String, dynamic>? : null;
    if (!linkOk || linkData == null) {
      throw Exception('Gagal mendapatkan link upload foto.');
    }

    final objectUuid = linkData['object_uuid'] as String;
    final uploadUrl = linkData['upload_url'] as String;
    final fields = Map<String, dynamic>.from(linkData['fields'] as Map);
    final contentType = (linkData['content_type'] as String?) ?? fields['Content-Type'] as String? ?? 'image/jpeg';

    final uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields.addAll(fields.map((key, value) => MapEntry(key, value.toString())))
      ..files.add(await http.MultipartFile.fromPath('file', path, contentType: MediaType.parse(contentType)));

    final uploadResponse = await uploadRequest.send();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception('Gagal mengunggah foto (status ${uploadResponse.statusCode}).');
    }

    return objectUuid;
  }

  // ===== SUBMIT =====
  Future<void> submitReport() async {
    alertMessage.value = '';
    resultData.value = null;

    if (photos.any((p) => p.isEmpty)) {
      alertMessage.value = "Harap lengkapi 4 foto!";
      showModal();
      return;
    }

    if (selectedPos.value.isEmpty || status.value.isEmpty) {
      alertMessage.value = "Harap lengkapi semua pilihan!";
      showModal();
      return;
    }

    if (latitude.value == 0 || longitude.value == 0) {
      alertMessage.value = "Gagal mendapatkan lokasi GPS.";
      showModal();
      return;
    }

    final statusApi = _statusToApi[status.value];
    if (statusApi == null) {
      alertMessage.value = "Status lokasi tidak valid.";
      showModal();
      return;
    }

    isLoading.value = true;

    try {
      loadingMessage.value = "Mengunggah foto (1/4)...";
      final objectUuids = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final file = File(photos[i]);
        if (!await file.exists()) {
          throw Exception("Foto ke-${i + 1} tidak ditemukan");
        }
        loadingMessage.value = "Mengunggah foto (${i + 1}/4)...";
        objectUuids.add(await _uploadPhotoAndGetObjectUuid(photos[i]));
      }

      loadingMessage.value = "Menyimpan laporan...";

      final payload = {
        "pos_uuid": selectedPos.value,
        "lat": latitude.value,
        "lng": longitude.value,
        "status": statusApi,
        "description": notes.value.isEmpty ? "Situasi aman terkendali." : notes.value,
        "object_uuids": objectUuids,
      };

      final reportRes = await GetConnect().post(
        "$BASE_API_URL/patrols",
        payload,
        headers: await _authHeaders(json: true),
      );

      final ok = reportRes.statusCode != null && reportRes.statusCode! >= 200 && reportRes.statusCode! < 300;
      if (ok) {
        resultData.value = reportRes.body is Map ? Map<String, dynamic>.from(reportRes.body as Map) : {};
        showModal();
        return;
      }

      _handleSubmitError(reportRes.body);
      showModal();
    } catch (e) {
      debugPrint('ReportPatroliController: gagal submit laporan: $e');
      alertMessage.value = "Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.";
      showModal();
    } finally {
      isLoading.value = false;
      loadingMessage.value = '';
    }
  }

  void _handleSubmitError(dynamic body) {
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code']?.toString() : null;
    final rawMessage = (error is Map ? error['message'] : null)?.toString();

    switch (code) {
      case 'NOT_ON_DUTY':
        alertMessage.value = 'Anda belum check-in. Lakukan check-in terlebih dahulu sebelum melapor patroli.';
        return;
      case 'POS_NOT_JAGA':
        alertMessage.value = 'Pos yang dipilih bukan pos jaga.';
        return;
      case 'OUTSIDE_POS_RADIUS':
        alertMessage.value = 'Anda berada di luar radius pos ini.';
        return;
      default:
        alertMessage.value = rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.';
    }
  }

  // ===== MODAL =====
  void showModal() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: buildModalContent(),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget buildModalContent() {
    const primaryBlue = Color(0xFF122C93);
    const orange = Color(0xFFF59E0B);
    const orangeDark = Color(0xFFB45309);

    if (alertMessage.value.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            "Gagal Memproses",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Text(
              alertMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: orangeDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => Get.back(),
              child: const Text(
                "Tutup",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Laporan Berhasil",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          "Data patroli berhasil dikirim.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Get.close(2);
              Get.offAllNamed('/');
            },
            child: const Text(
              "Selesai",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
