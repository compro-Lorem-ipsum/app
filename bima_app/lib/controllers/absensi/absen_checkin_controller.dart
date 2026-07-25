// Controller untuk halaman Check-in / Check-out.
// Menggabungkan 3 hal dalam satu halaman: (1) cek GPS & radius terhadap
// Pos, (2) kamera depan live embedded untuk verifikasi wajah, dan
// (3) submit absensi ke API beserta dialog hasil (sukses/gagal).

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class AbsenCheckinController extends GetxController {
  late final bool isCheckIn;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var distanceMeter = 0.0.obs;
  var isInRadius = false.obs;
  var isLoadingLocation = true.obs;

  // Placeholder posisi Pos Utama, menunggu data mitra dari backend.
  static const double posLatitude = -6.200000;
  static const double posLongitude = 106.816666;
  static const double radiusMeter = 100;

  // ===== KAMERA (live preview langsung di halaman ini) =====
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var photoTaken = false.obs;
  var photoPath = ''.obs;

  var isSubmitting = false.obs;
  var resultData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    isCheckIn = (args is Map && args['isCheckIn'] is bool) ? args['isCheckIn'] as bool : true;
    _getCurrentLocation();
    _initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  // ===== LOKASI =====
  Future<void> _getCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = position.latitude;
      longitude.value = position.longitude;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        posLatitude,
        posLongitude,
      );
      distanceMeter.value = distance;
      isInRadius.value = distance <= radiusMeter;
    } catch (e) {
      debugPrint("Gagal mengambil lokasi: $e");
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void refreshLocation() => _getCurrentLocation();

  // ===== KAMERA =====
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      debugPrint("Gagal mengakses kamera: $e");
    }
  }

  Future<void> capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    try {
      final image = await cameraController!.takePicture();
      photoPath.value = image.path;
      photoTaken.value = true;
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
    }
  }

  void retakePhoto() {
    photoTaken.value = false;
    photoPath.value = '';
  }

  void handleCancel() {
    Get.back();
  }

  // ===== SUBMIT ABSENSI =====
  Future<void> confirmAttendance() async {
    if (photoPath.value.isEmpty) return;

    isSubmitting.value = true;

    try {
      final form = FormData({
        'image': MultipartFile(
          File(photoPath.value),
          filename: 'attendance.png',
          contentType: 'image/png',
        ),
        'lat': latitude.value.toString(),
        'lng': longitude.value.toString(),
      });

      final response = await GetConnect().post(
        "$BASE_API_URL/v1/absensi/record",
        form,
      );

      final result = response.body;
      resultData.value = result;

      if (result == null) {
        showResultDialog(type: 'SERVER_ERROR');
        return;
      }

      String msg = (result['message'] ?? "").toString().toLowerCase();
      bool isSuccess = result['data'] != null;

      if (isSuccess) {
        showResultDialog(type: 'SUCCESS');
      } else if (msg.contains("jarak") || msg.contains("radius") || msg.contains("pos utama")) {
        showResultDialog(type: 'LOCATION_INVALID');
      } else if (msg.contains("wajah") || msg.contains("face")) {
        showResultDialog(type: 'FACE_MISMATCH');
      } else if (msg.contains("jadwal") || msg.contains("terlalu awal") || msg.contains("menyelesaikan shift")) {
        showResultDialog(type: 'NO_SCHEDULE');
      } else if (msg.contains("satpam") || msg.contains("user")) {
        showResultDialog(type: 'USER_ERROR');
      } else {
        resultData.value = {'message': msg.isEmpty ? "Terjadi kesalahan server" : result['message']};
        showResultDialog(type: 'SERVER_ERROR');
      }
    } catch (e) {
      debugPrint("Error Exception: $e");
      resultData.value = {'message': "Gagal terhubung ke server. Periksa koneksi internet."};
      showResultDialog(type: 'SERVER_ERROR');
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatJamAbsensi(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return "-";
    final dateTime = DateTime.parse(isoTime).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // ===== DIALOG HASIL =====
  void showResultDialog({required String type}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildDialogContent(type),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDialogContent(String type) {
    const titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFA80808));
    const titleSuccessStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF122C93));
    const primaryBtnStyle = Color(0xFF122C93);

    switch (type) {
      case 'LOCATION_INVALID':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFE4E6), shape: BoxShape.circle),
              child: const Center(
                child: HeroIcon(HeroIcons.mapPin, style: HeroIconStyle.outline, size: 32, color: Color(0xFFA80808)),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Lokasi Tidak Valid", style: titleStyle),
            const SizedBox(height: 10),
            const Text("Posisi Anda tidak sesuai dengan ketentuan.", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Jarak tidak memasuki radius Pos", style: TextStyle(color: Color(0xFFA80808))),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    refreshLocation();
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: const Text("Cek GPS", style: TextStyle(color: primaryBtnStyle)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  onPressed: () => Get.back(),
                  child: const Text("Kembali", style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        );

      case 'FACE_MISMATCH':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFE4E6), shape: BoxShape.circle),
              child: const Center(
                child: HeroIcon(HeroIcons.exclamationTriangle, style: HeroIconStyle.outline, size: 32, color: Color(0xFFA80808)),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Wajah Tidak Dikenali", style: titleStyle),
            const SizedBox(height: 10),
            const Text("Sistem gagal memverifikasi identitas.", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Verifikasi wajah gagal", style: TextStyle(color: Color(0xFFA80808))),
              ]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  child: const Text("Coba Lagi", style: TextStyle(color: primaryBtnStyle)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  onPressed: () {
                    Get.back();
                    retakePhoto();
                  },
                  child: const Text("Ambil Foto Ulang", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );

      case 'SUCCESS':
        final data = resultData.value?['data'] ?? {};
        final status = (data['status'] ?? '').toString();
        final kategori = (data['kategori'] ?? '').toString();
        final jarak = data['distance'];
        final waktu = formatJamAbsensi(data['time']);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(resultData.value?['message'] ?? "Berhasil", style: titleSuccessStyle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(status.replaceAll('_', ' '), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF122C93))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Text("Waktu Absensi", style: TextStyle(fontSize: 14)),
                Text(waktu, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 12),
            if (jarak != null) Text("Jarak: ${jarak.toStringAsFixed(1)} m", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              kategori.toUpperCase(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kategori.toLowerCase().contains('tepat') ? Colors.green : Colors.orange),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                onPressed: () {
                  Get.back();
                  Get.offAllNamed('/');
                },
                child: const Text("Selesai", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );

      case 'NO_SCHEDULE':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
              child: const Center(
                child: HeroIcon(HeroIcons.clock, style: HeroIconStyle.outline, size: 32, color: Color(0xFFD97706)),
              ),
            ),
            const SizedBox(height: 12),
            const Text("Informasi Jadwal", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFEDD5))),
              child: Text(
                resultData.value?['message'] ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFD97706)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                onPressed: () {
                  Get.back();
                  Get.offAllNamed('/');
                },
                child: const Text("Kembali ke Beranda", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );

      case 'SERVER_ERROR':
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFE4E6), shape: BoxShape.circle),
              child: const Center(
                child: HeroIcon(HeroIcons.exclamationTriangle, style: HeroIconStyle.outline, size: 32, color: Color(0xFFA80808)),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Gagal", style: titleStyle),
            const SizedBox(height: 10),
            const Text("Terjadi kesalahan saat memproses permintaan.", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Terjadi kesalahan jaringan.", style: TextStyle(color: Color(0xFFA80808))),
              ]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    child: const Text("Tutup", style: TextStyle(color: primaryBtnStyle)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: () {
                      Get.back();
                      confirmAttendance();
                    },
                    child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
