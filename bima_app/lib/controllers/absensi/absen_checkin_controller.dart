// Controller untuk halaman Check-in / Check-out.
// Menggabungkan 3 hal dalam satu halaman: (1) cek GPS & radius terhadap
// Pos, (2) kamera depan live embedded untuk verifikasi wajah, dan
// (3) submit absensi ke API beserta dialog hasil (sukses/gagal).

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:heroicons/heroicons.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../services/auth_service.dart';
import '../../services/tracking_service.dart';
import '../../services/workmanager_callback.dart';
import '../../widgets/success_screen.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class AbsenCheckinController extends GetxController {
  late final bool isCheckIn;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var accuracyMeter = 0.0.obs;
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
      accuracyMeter.value = position.accuracy;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        posLatitude,
        posLongitude,
      );
      distanceMeter.value = distance;
      // SEMENTARA: anggap selalu dalam radius dari lokasi mana pun supaya
      // check-in/out bisa dites tanpa harus berada dekat Pos Utama.
      // TODO: kembalikan ke `distance <= radiusMeter` kalau sudah siap
      // menegakkan pembatasan radius sungguhan.
      isInRadius.value = true;
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
  // Kontrak: POST /attendance/upload-url (reserve selfie object) lalu POST
  // file ke GCS, baru POST /attendance/check-in atau /attendance/check-out
  // dengan { lat, lng, object_uuid, accuracy_m }. Body strict — field yang
  // tidak didokumentasikan (mis. gps_incomplete lama) ditolak 422, jadi
  // tidak dikirim di sini.
  Future<void> confirmAttendance() async {
    if (photoPath.value.isEmpty) return;

    isSubmitting.value = true;
    try {
      // Saat check-out: hentikan capture & ambil titik penutup lokal
      // sebelum submit. Sinkronisasi titik GPS itu sendiri lewat endpoint
      // terpisah (POST /attendance/tracking) yang belum diselaraskan di
      // TrackingService — di luar cakupan perubahan ini.
      if (!isCheckIn) {
        await TrackingService().pauseCapture();
        await TrackingService().captureFinalPoint();
      }

      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi tidak ditemukan, silakan masuk kembali.');
      }

      final objectUuid = await _uploadSelfieAndGetObjectUuid(token);

      final endpoint = isCheckIn ? 'check-in' : 'check-out';
      final response = await GetConnect().post(
        '$BASE_API_URL/attendance/$endpoint',
        {
          'lat': latitude.value,
          'lng': longitude.value,
          'object_uuid': objectUuid,
          'accuracy_m': accuracyMeter.value,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = response.body;
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;

      if (ok) {
        resultData.value = {'data': body is Map ? body['data'] : null};
        final user = await AuthService().getUser();
        final satpamUuid = (user?['uuid'] as String?) ?? '';
        await _afterAttendanceSuccess(satpamUuid);
        _showSuccessScreen();
        return;
      }

      _handleAttendanceError(body);
    } catch (e) {
      debugPrint("AbsenCheckinController: gagal terhubung ke server, pakai fallback offline untuk testing FE: $e");
      // MODE FALLBACK: exception di sini umumnya berarti backend tidak
      // terjangkau (mis. connection refused) — supaya bagian FE tetap bisa
      // dites tanpa backend, anggap absensi berhasil pakai data lokal.
      await _handleOfflineFallback();
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Langkah 1: minta upload-link (GCS signed POST policy) untuk foto
  /// selfie absensi. Langkah 2: POST file langsung ke bucket GCS dengan
  /// field-field yang dikembalikan (fields dulu, file terakhir — syarat
  /// GCS POST policy). Mengembalikan `object_uuid` untuk dikirim saat
  /// check-in/check-out.
  Future<String> _uploadSelfieAndGetObjectUuid(String token) async {
    final ext = photoPath.value.contains('.') ? photoPath.value.split('.').last.toLowerCase() : 'jpg';

    final linkRes = await GetConnect().post(
      '$BASE_API_URL/attendance/upload-url',
      {'ext': ext},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        photoPath.value,
        contentType: MediaType.parse(contentType),
      ));

    final uploadResponse = await uploadRequest.send();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception('Gagal mengunggah foto (status ${uploadResponse.statusCode}).');
    }

    return objectUuid;
  }

  /// Terjemahkan `error.code` dari backend ke dialog yang sudah ada.
  /// Kode-kode ini mengikuti dokumentasi endpoint Attendance — lihat
  /// bagian Error Codes.
  void _handleAttendanceError(dynamic body) {
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code']?.toString() : null;
    final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();
    resultData.value = {'message': rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.'};

    switch (code) {
      case 'OUTSIDE_POS_RADIUS':
        showResultDialog(type: 'LOCATION_INVALID');
        return;
      case 'FACE_NOT_MATCHED':
      case 'FACE_NOT_ENROLLED':
        showResultDialog(type: 'FACE_MISMATCH');
        return;
      case 'NO_OPEN_SHIFT':
      case 'OUTSIDE_CHECK_IN_WINDOW':
      case 'NO_UTAMA_POS':
      case 'NO_CLIENT_SCOPE':
      case 'ALREADY_CHECKED_IN':
      case 'NOT_CHECKED_IN':
        showResultDialog(type: 'NO_SCHEDULE');
        return;
    }

    if (code != null && code.startsWith('FACE_')) {
      showResultDialog(type: 'FACE_MISMATCH');
      return;
    }

    showResultDialog(type: 'SERVER_ERROR');
  }

  /// Dipakai hanya untuk testing FE selama backend `/v1/absensi/record`
  /// belum tersedia: simulasikan hasil sukses dari data lokal yang sudah
  /// ada (radius, waktu sekarang) supaya alur UI (dialog sukses, mulai/
  /// hentikan tracking) tetap bisa dicoba end-to-end tanpa server.
  Future<void> _handleOfflineFallback() async {
    debugPrint('AbsenCheckinController: backend tidak terjangkau, pakai fallback offline untuk testing FE.');
    resultData.value = {
      'message': 'Absensi berhasil dicatat (mode offline — backend belum tersedia)',
      'data': {
        'status': isCheckIn ? 'CHECK_IN' : 'CHECK_OUT',
        'kategori': isInRadius.value ? 'Tepat Waktu' : 'Terlambat',
        'distance': distanceMeter.value,
        'time': DateTime.now().toIso8601String(),
      },
    };
    final user = await AuthService().getUser();
    final satpamUuid = (user?['uuid'] as String?) ?? '';
    await _afterAttendanceSuccess(satpamUuid);
    _showSuccessScreen();
  }

  /// Tampilkan halaman sukses penuh (bukan dialog) sesuai desain Figma:
  /// icon centang animasi + kartu WAKTU/LOKASI/(STATUS khusus check-in).
  void _showSuccessScreen() {
    final data = resultData.value?['data'] ?? {};
    final waktu = formatJamAbsensi(data['time'] as String?);
    final kategori = (data['kategori'] ?? '').toString();

    Get.off(() => SuccessScreen(
          title: 'Behasil',
          subtitle: 'Absensi Anda telah berhasil disimpan.',
          details: {
            'WAKTU': waktu,
            'LOKASI': 'Pos Utama',
            if (isCheckIn) 'STATUS': kategori.isEmpty ? '-' : kategori,
          },
          buttonLabel: 'Kembali ke Beranda',
          buttonWidth: 316,
          buttonHeight: 60,
          buttonBorderRadius: 40,
          buttonFontSize: 20,
          onButtonPressed: () => Get.offAllNamed('/'),
        ));
  }

  /// Efek samping setelah absensi tercatat (baik sukses sungguhan maupun
  /// fallback offline): mulai tracking GPS saat check-in, atau hentikannya
  /// & bersihkan cache lokal saat check-out.
  Future<void> _afterAttendanceSuccess(String satpamUuid) async {
    if (isCheckIn) {
      await TrackingService().startTracking(absensiUuid: satpamUuid);
      await initializeBackgroundTracking();
    } else {
      // KHUSUS DEBUGGING: tulis peta rute GPS sesi ini ke file HTML lokal
      // supaya bisa langsung diperiksa (lihat TrackingService.exportDebugMap).
      // Di-await (bukan fire-and-forget) supaya sempat membaca antrian
      // SEBELUM stopTracking() membersihkannya. Tidak menambah UI apa pun &
      // tidak pernah jalan di build production.
      if (kDebugMode) {
        await TrackingService().exportDebugMap(satpamUuid: satpamUuid);
      }
      // stopTracking() membersihkan seluruh cache GPS lokal shift ini (lihat
      // catatan MODE FALLBACK di TrackingService.stopTracking).
      await TrackingService().stopTracking();
      await cancelBackgroundTracking();
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
