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
      alertMessage.value = "Lokasi GPS belum terdeteksi.";
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
        "keterangan":
            notes.value.isEmpty ? "Situasi aman terkendali." : notes.value,
        "filenames": filenames,
      };

      final reportRes = await GetConnect().post(
        "$BASE_API_URL/v1/patroli",
        payload,
        headers: {"Content-Type": "application/json"},
      );

      resultData.value = reportRes.body;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: buildModalContent(),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget buildModalContent() {
    final isLocationError =
        resultData.value?['message']?.toLowerCase().contains("location") ??
            false;

    if (alertMessage.value.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, size: 60, color: Colors.orange),
          const SizedBox(height: 12),
          const Text("Gagal Memproses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(alertMessage.value, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF122C93)),
            onPressed: () { Get.back(); },
            child: const Text("Tutup", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    }

    if (isLocationError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          const Text("Lokasi Tidak Valid",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Jarak: ${resultData.value?['distance']}"),
          Text("Maksimal: ${resultData.value?['allowed']}"),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF122C93)),
            onPressed: () { Get.back(); },
            child: const Text("Tutup", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 60, color: Color(0xFF122C93)),
        const SizedBox(height: 12),
        const Text("Laporan Berhasil",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Data patroli berhasil dikirim."),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF122C93),
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
      ],
    );
  }
}
