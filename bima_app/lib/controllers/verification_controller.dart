import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:heroicons/heroicons.dart';

// --- KONFIGURASI API ---
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class VerificationController extends GetxController {
  // --- STATE ---
  var isSubmitting = false.obs;
  var photoPath = ''.obs;
  var latitude = ''.obs;
  var longitude = ''.obs;
  
  // Menyimpan hasil response untuk ditampilkan di dialog
  var resultData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    
    // 1. Ambil data yang dikirim dari halaman sebelumnya
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>;
      photoPath.value = args['photo'] ?? '';
      latitude.value = args['latitude'] ?? '';
      longitude.value = args['longitude'] ?? '';
    }

    // 2. FAILSAFE: Jika lokasi kosong (user terlalu cepat), ambil ulang sekarang!
    if (_isLocationEmpty()) {
      print("⚠️ Lokasi kosong dari page sebelumnya, mencoba mengambil ulang...");
      _getCurrentLocation();
    }
  }

  bool _isLocationEmpty() {
    return latitude.value.isEmpty || longitude.value.isEmpty || latitude.value == "0";
  }

  // --- LOGIC GPS MANDIRI ---
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // Ambil posisi (High Accuracy)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium
      );

      latitude.value = position.latitude.toString();
      longitude.value = position.longitude.toString();
      print("✅ Lokasi berhasil diperbarui: ${latitude.value}, ${longitude.value}");
      
    } catch (e) {
      print("❌ Gagal mengambil lokasi ulang: $e");
    }
  }

  // --- LOGIC SUBMIT ---
  Future<void> confirmAttendance() async {
    // 3. FINAL CHECK: Sebelum submit, pastikan lokasi sudah ada
    if (_isLocationEmpty()) {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      await _getCurrentLocation();
      if (Get.isDialogOpen ?? false) Get.back(); // Tutup loading

      // Jika masih kosong juga, tolak submit
      if (_isLocationEmpty()) {
        Get.snackbar(
          "Gagal Mendapatkan Lokasi", 
          "Pastikan GPS aktif dan izin lokasi diberikan.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
        return; 
      }
    }

    isSubmitting.value = true;
    
    try {
      final form = FormData({
        'image': MultipartFile(
          File(photoPath.value),
          filename: 'attendance.png',
          contentType: 'image/png',
        ),
        'lat': latitude.value,
        'lng': longitude.value,
      });


      print("📤 Mengirim Absensi... Lat: ${latitude.value}, Long: ${longitude.value}");

      final response = await GetConnect().post(
        "$BASE_API_URL/v1/absensi/record",
        form,
      );
      
      final result = response.body;
      resultData.value = result; // Simpan untuk dipakai di dialog

      // --- HANDLING RESPONSE ---
      if (result == null) {
          showResultDialog(type: 'SERVER_ERROR');
          return;
      }

      // Logic Error Message (Sama persis dengan React TSX)
      // 1. Lowercase message
      String msg = (result['message'] ?? "").toString().toLowerCase();
      // 2. Cek Success (adanya data)
      bool isSuccess = result['data'] != null;

      if (isSuccess) {
        showResultDialog(type: 'SUCCESS');
      } 
      // isLocationError (jarak, radius, pos utama)
      else if (msg.contains("jarak") || msg.contains("radius") || msg.contains("pos utama")) {
        showResultDialog(type: 'LOCATION_INVALID');
      } 
      // isFaceError (wajah, face)
      else if (msg.contains("wajah") || msg.contains("face")) {
        showResultDialog(type: 'FACE_MISMATCH');
      }
      // isScheduleError (jadwal, terlalu awal, menyelesaikan shift)
      else if (msg.contains("jadwal") || msg.contains("terlalu awal") || msg.contains("menyelesaikan shift")) {
        showResultDialog(type: 'NO_SCHEDULE');
      }
      // isUserError (satpam, user)
      else if (msg.contains("satpam") || msg.contains("user")) {
        // Menggunakan tipe yang akan jatuh ke default/error template jika UI khusus belum ada
        showResultDialog(type: 'USER_ERROR');
      }
      else {
        resultData.value = {'message': msg.isEmpty ? "Terjadi kesalahan server" : result['message']};
        showResultDialog(type: 'SERVER_ERROR');
      }

    } catch (e) {
      print("❌ Error Exception: $e");
      resultData.value = {'message': "Gagal terhubung ke server. Periksa koneksi internet."};
      showResultDialog(type: 'SERVER_ERROR');
    } finally {
      isSubmitting.value = false;
    }
  }

  void handleCancel() {
    Get.back();
  }

  String formatJamAbsensi(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return "-";
    final dateTime = DateTime.parse(isoTime).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
  
  // --- DIALOG UI HELPER ---
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
    // Helper Styles
    const titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFA80808));
    const titleSuccessStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF122C93));
    const primaryBtnStyle = Color(0xFF122C93);
    
    switch (type) {
      case 'LOCATION_INVALID':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(
                width: 64,   // w-16
                height: 64,  // h-16
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6), // bg-red-100
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HeroIcon(
                    HeroIcons.mapPin,
                    style: HeroIconStyle.outline,
                    size: 32, // h-8 w-8
                    color: Color(0xFFA80808),
                  ),
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
               child:Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Jarak tidak memasuki radius Pos", style: const TextStyle(color: Color(0xFFA80808)))
                ]),
             ),
             const SizedBox(height: 20),
             Row(children: [
               Expanded(child: OutlinedButton(
                 onPressed: () {
                   Get.back(); // Tutup dialog
                   _getCurrentLocation(); // Coba ambil lokasi ulang
                 }, 
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), ), ),
                 child: const Text("Cek GPS", style: TextStyle(color: primaryBtnStyle)),
               )),
               const SizedBox(width: 10),
               Expanded(child: ElevatedButton(
                 style: ElevatedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), ), ),
                 onPressed: () { Get.back(); },
                 child: const Text("Kembali", style: TextStyle(color: Colors.white)),
               ))
             ])
          ],
        );

      case 'FACE_MISMATCH':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, // w-16
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6), // bg-red-100
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HeroIcon(
                  HeroIcons.exclamationTriangle, // icon segitiga
                  style: HeroIconStyle.outline,
                  size: 32, // h-8 w-8
                  color: Color(0xFFA80808),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Wajah Tidak Dikenali", style: titleStyle),
            const SizedBox(height: 10),
            Text("Sistem gagal memverifikasi identitas.", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
               child:Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Verifikasi wajah gagal", style: const TextStyle(color: Color(0xFFA80808)))
                ]),
             ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12) ),
                  child: const Text(
                    "Coba Lagi",
                    style: TextStyle(color: primaryBtnStyle),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12) ),
                  onPressed: () {
                    Get.back();
                    handleCancel();
                  },
                  child: const Text(
                    "Ambil Foto Ulang",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        );

      case 'SUCCESS':
      final data = resultData.value?['data'] ?? {};
      final status = (data['status'] ?? '').toString();       // CHECK_IN
      final kategori = (data['kategori'] ?? '').toString();   // Terlambat / Tepat Waktu
      final jarak = data['distance'];
      final waktu = formatJamAbsensi(data['time']);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resultData.value?['message'] ?? "Berhasil",
            style: titleSuccessStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // STATUS CHECK IN / OUT
          Text(
            status.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF122C93),
            ),
          ),

          const SizedBox(height: 16),

          // WAKTU ABSENSI (DARI BACKEND)
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Waktu Absensi",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  waktu,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // JARAK
          if (jarak != null)
            Text(
              "Jarak: ${jarak.toStringAsFixed(1)} m",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

          const SizedBox(height: 8),

          // TERLAMBAT / TEPAT WAKTU
          Text(
            kategori.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kategori.toLowerCase().contains('tepat')
                  ? Colors.green
                  : Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              onPressed: () {
                Get.close(2); // dialog + VerificationView
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


      case 'NO_SCHEDULE':
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // 🔶 Orange Circle Icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0), // bg-orange-100
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: HeroIcon(
                HeroIcons.clock,
                style: HeroIconStyle.outline,
                size: 32,
                color: Color(0xFFD97706), // text-[#d97706]
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Informasi Jadwal",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),

          const SizedBox(height: 16),

          // 🔶 Orange Info Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // bg-orange-50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)), // border-orange-100
            ),
            child: Text(
              resultData.value?['message'] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD97706),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔶 Full Width Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle), backgroundColor: primaryBtnStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              onPressed: () {
                Get.back();
                Get.offAllNamed('/');
              },
              child: const Text(
                "Kembali ke Beranda",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              width: 64, // w-16
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6), // bg-red-100
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HeroIcon(
                  HeroIcons.exclamationTriangle, // icon segitiga
                  style: HeroIconStyle.outline,
                  size: 32, // h-8 w-8
                  color: Color(0xFFA80808),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Gagal", style: titleStyle),
            const SizedBox(height: 10),
            Text("Terjadi kesalahan saat memproses permintaan.", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
               child:Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Terjadi kesalahan jaringan.", style: const TextStyle(color: Color(0xFFA80808)))
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
                    child: const Text(
                      "Tutup",
                      style: TextStyle(color: primaryBtnStyle),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child : ElevatedButton(
                    style: ElevatedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle),backgroundColor: primaryBtnStyle, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: () {
                      Get.back();
                      confirmAttendance();
                    },
                    child: const Text(
                      "Coba Lagi",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              ],
            )
          ],
        );
  
    }
  }
}