// Controller untuk halaman Laporan Kejadian (lapor insiden di lokasi).
//
// POST /event-reports - satpam - { lat, lng, description, object_uuids?[0-4] }
// Tidak terikat jadwal dan tidak mensyaratkan check-in (beda dari
// Laporan Patroli). Foto opsional (0-4), diunggah satu per satu lewat
// kontrak 2-langkah POST /event-reports/upload-url -> object_uuid, lalu
// POST multipart ke GCS — pola yang sama dengan patroli/absensi.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/primary_button.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class LaporKejadianController extends GetxController {
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;
  final gpsActive = false.obs;

  final photos = List<String>.filled(4, '').obs;
  final descriptionController = TextEditingController();
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    getGPS();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

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
      gpsActive.value = true;
    } catch (_) {}
  }

  Future<void> goToCamera(int index) async {
    final result = await Get.toNamed('/take-photo-patroli');

    if (result != null && result is String) {
      photos[index] = result;
      photos.refresh();
    }
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  Future<Map<String, String>?> _authHeaders({bool json = false}) async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return json ? {'Content-Type': 'application/json'} : null;
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// Upload satu foto lewat kontrak 2-langkah: POST
  /// /event-reports/upload-url untuk reservasi object, lalu POST
  /// multipart ke GCS (fields dulu, file terakhir).
  Future<String> _uploadPhotoAndGetObjectUuid(String path) async {
    final linkRes = await GetConnect().post(
      '$_baseApiUrl/event-reports/upload-url',
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

  Future<void> submitReport() async {
    if (isSubmitting.value) return;

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      Get.snackbar(
        'Deskripsi wajib diisi',
        'Jelaskan kejadian yang sedang terjadi.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final objectUuids = <String>[];
      for (final path in photos) {
        if (path.isEmpty) continue;
        objectUuids.add(await _uploadPhotoAndGetObjectUuid(path));
      }

      final response = await GetConnect().post(
        '$_baseApiUrl/event-reports',
        {
          'lat': latitude.value,
          'lng': longitude.value,
          'description': description,
          if (objectUuids.isNotEmpty) 'object_uuids': objectUuids,
        },
        headers: await _authHeaders(json: true),
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        _showSuccessDialog();
        return;
      }

      _showSubmitError(response.body);
    } catch (e) {
      debugPrint('LaporKejadianController: gagal mengirim laporan: $e');
      _showSubmitError(null, fallback: 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSubmitError(dynamic body, {String? fallback}) {
    final error = body is Map ? body['error'] : null;
    final rawMessage = (error is Map ? error['message'] : null)?.toString();
    Get.snackbar(
      'Gagal Mengirim',
      rawMessage ?? fallback ?? 'Terjadi kesalahan, silakan coba lagi.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Laporan Berhasil',
                textAlign: TextAlign.center,
                style: AppText.bold.copyWith(fontSize: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Laporan Berhasil Dikirim',
                textAlign: TextAlign.center,
                style: AppText.regular.copyWith(fontSize: 13, color: AppColors.disabled),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: 'Selesai',
                  onPressed: () {
                    Get.back();
                    if (Get.key.currentState?.canPop() ?? false) {
                      Get.back();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
