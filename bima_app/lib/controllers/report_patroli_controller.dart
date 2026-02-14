import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class ReportPatroliController extends GetxController {
  // ===== STATE =====
  var listSatpam = <dynamic>[].obs;
  var listPos = <dynamic>[].obs;

  var selectedSatpam = ''.obs;
  var selectedPos = ''.obs;
  var status = ''.obs;
  var notes = ''.obs;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  // base64 image (4 foto)
  var photos = List<String>.filled(4, "").obs;

  var isLoading = false.obs;
  var loadingMessage = ''.obs;

  var resultData = Rxn<Map<String, dynamic>>();
  var alertMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSatpam();
    getGPS();
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

    // Jika kamera mengembalikan path foto
    if (result != null && result is String) {
      photos[index] = result;
      photos.refresh(); 
    }
  }

  // ===== API OPTIONS =====
  Future<void> fetchSatpam() async {
    final res = await GetConnect().get("$BASE_API_URL/v1/patroli/options");
    if (res.body?['data'] != null) {
      listSatpam.value = res.body['data'];
    }
  }

  Future<void> fetchPos(String satpamUuid) async {
    selectedPos.value = '';
    listPos.clear();

    final res =
        await GetConnect().get("$BASE_API_URL/v1/patroli/options/$satpamUuid");
    if (res.body?['data'] != null) {
      listPos.value = res.body['data'];
    }
  }

  // ===== PHOTO RESULT FROM CAMERA =====
  void setPhoto(int index, String base64) {
    photos[index] = base64;
    photos.refresh();
  }

  // ===== SUBMIT (SAMA DENGAN VITE) =====
  Future<void> submitReport() async {
    alertMessage.value = '';
    resultData.value = null;

    // VALIDASI
    if (photos.any((p) => p.isEmpty)) {
      alertMessage.value = "Harap lengkapi 4 foto!";
      showModal();
      return;
    }

    if (selectedSatpam.value.isEmpty ||
        selectedPos.value.isEmpty ||
        status.value.isEmpty) {
      alertMessage.value = "Harap lengkapi semua pilihan!";
      showModal();
      return;
    }

    if (latitude.value == 0 || longitude.value == 0) {
      alertMessage.value = "Gagal mendapatkan lokasi GPS.";
      showModal();
      return;
    }

    isLoading.value = true;

    try {
      loadingMessage.value = "1/3 Meminta Slot Upload...";

      // === STEP 1: GET UPLOAD URL ===
      final urlRes =
          await GetConnect().get("$BASE_API_URL/v1/patroli/upload-urls");

      if (urlRes.body?['data'] == null) {
        throw "Gagal mendapatkan upload URL";
      }

      final uploadUrls = urlRes.body['data']['upload_urls'];
      final filenames = urlRes.body['data']['filenames'];

      loadingMessage.value = "2/3 Mengunggah Foto...";

      // === STEP 2: UPLOAD FOTO ===
      for (int i = 0; i < photos.length; i++) {
        final file = File(photos[i]);

        if (!await file.exists()) {
          throw "Foto ke-${i + 1} tidak ditemukan";
        }

        final bytes = await file.readAsBytes();

        final uploadRes = await http.put(
          Uri.parse(uploadUrls[i]),
          headers: {
            "Content-Type": "image/jpeg",
          },
          body: bytes,
        );

        if (uploadRes.statusCode != 200) {
          throw "Gagal upload foto ke-${i + 1}";
        }

      }

      loadingMessage.value = "3/3 Menyimpan Laporan...";

      // === STEP 3: SAVE REPORT ===
      final payload = {
        "satpam_uuid": selectedSatpam.value,
        "pos_uuid": selectedPos.value,
        "lat": latitude.value,
        "lng": longitude.value,
        "status_lokasi": status.value,
        "keterangan": notes.value.isEmpty 
            ? "Situasi aman terkendali." 
            : notes.value,
        "filenames": filenames,
      };

      final reportRes = await GetConnect().post(
        "$BASE_API_URL/v1/patroli",
        payload,
        headers: {"Content-Type": "application/json"},
      );

      resultData.value = reportRes.body;

      print("STATUS CODE: ${reportRes.statusCode}");
      print("BODY: ${reportRes.body}");


      showModal();
    } catch (e) {
      alertMessage.value = e.toString();
      showModal();
    } finally {
      isLoading.value = false;
      loadingMessage.value = '';
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

    final isLocationError =
      resultData.value?['message']?.contains("Jarak tidak memasuki radius Pos") ?? false;
    
    final isScheduleError = 
      resultData.value?['message']?.contains("Tidak ada jadwal untuk hari ini") ?? false;

    if (isScheduleError) {
      alertMessage.value = 'Tidak ada jadwal untuk hari ini';
    }

    if (isLocationError) {
      alertMessage.value = 'Jarak tidak memasuki radius Pos';
    }

    // ================================
    // 🔶 VALIDATION ERROR (ORANGE)
    // ================================
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
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFFEDD5)),
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

    // ================================
    // 🔵 SUCCESS
    // ================================
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
