import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';  // Jangan lupa add: flutter pub add geolocator

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
        // Bisa trigger dialog minta nyalakan GPS disini jika mau
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
        desiredAccuracy: LocationAccuracy.high
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
      // Coba ambil sekali lagi (blocking / tunggu sampai selesai)
      // Tampilkan loading sebentar jika perlu, atau blocking await
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
         showResultDialog(type: 'SERVER_ERROR'); // Response null/kosong
         return;
      }

      String msg = (result['message'] ?? "").toString();

      if (msg.contains("Location invalid")) {
        showResultDialog(type: 'LOCATION_INVALID');
      } 
      else if (msg == "Face not recognized") {
        showResultDialog(type: 'FACE_MISMATCH');
      }
      else if (msg == "No schedule found for this Satpam today.") {
        showResultDialog(type: 'NO_SCHEDULE');
      }
      else if (msg.contains("completed your shift")) {
        showResultDialog(type: 'SHIFT_COMPLETED');
      }
      else if (response.statusCode == 200 || response.statusCode == 201) {
        showResultDialog(type: 'SUCCESS');
      }
      else {
        // Fallback error message dari server
        resultData.value = {'message': msg.isEmpty ? "Terjadi kesalahan server" : msg};
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
             const Icon(Icons.location_off_outlined, color: Color(0xFFA80808), size: 60),
             const SizedBox(height: 10),
             const Text("Lokasi Tidak Valid", style: titleStyle),
             const SizedBox(height: 10),
             const Text("Anda berada di luar jangkauan area presensi.", textAlign: TextAlign.center),
             const SizedBox(height: 15),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
               child: Column(
                 children: [
                   Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                     const Text("Jarak Anda"),
                     Text("${resultData.value?['distance']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA80808)))
                   ]),
                   Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                     const Text("Maksimal"),
                     Text("${resultData.value?['allowed']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                   ]),
                 ],
               ),
             ),
             const SizedBox(height: 20),
             Row(children: [
               Expanded(child: OutlinedButton(
                 onPressed: () {
                   Get.back(); // Tutup dialog
                   _getCurrentLocation(); // Coba ambil lokasi ulang
                 }, 
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle)),
                 child: const Text("Cek GPS Ulang", style: TextStyle(color: primaryBtnStyle)),
               )),
               const SizedBox(width: 10),
               Expanded(child: ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle),
                 onPressed: () { Get.back(); },
                 child: const Text("Tutup", style: TextStyle(color: Colors.white)),
               ))
             ])
          ],
        );

      case 'FACE_MISMATCH':
        double similarity = double.tryParse((resultData.value?['similarity'] ?? "0").toString()) ?? 0;
        similarity *= 100;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.face_retouching_off, color: Color(0xFFA80808), size: 60),
            const SizedBox(height: 10),
            const Text("Wajah Tidak Dikenali", style: titleStyle),
            const SizedBox(height: 10),
            Text("Sistem mendeteksi kemiripan wajah terlalu rendah (${similarity.toStringAsFixed(1)}%).", textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[100]!)),
               child: const Text("Silakan periksa pencahayaan sekitar dan pastikan wajah Anda pas di dalam frame.", style: TextStyle(color: Color(0xFFA80808), fontSize: 13), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
             Row(children: [
               Expanded(child: OutlinedButton(
                 onPressed: () => Get.back(), // Tutup dialog, user bisa tekan tombol konfirmasi lagi
                 style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBtnStyle)),
                 child: const Text("Coba Lagi", style: TextStyle(color: primaryBtnStyle)),
               )),
               const SizedBox(width: 10),
               Expanded(child: ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle),
                 onPressed: () { Get.back(); handleCancel(); }, // Kembali ke kamera
                 child: const Text("Foto Ulang", style: TextStyle(color: Colors.white)),
               ))
             ])
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnStyle,
              ),
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
      case 'SHIFT_COMPLETED':
      case 'SERVER_ERROR':
      default:
        // Generic Error Template
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Icon(Icons.error_outline, color: Color(0xFFA80808), size: 60),
             const SizedBox(height: 10),
             const Text("Gagal", style: titleStyle),
             const SizedBox(height: 10),
             Text(resultData.value?['message'] ?? "Terjadi kesalahan yang tidak diketahui.", textAlign: TextAlign.center),
             const SizedBox(height: 20),
             SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBtnStyle),
                onPressed: () => Get.back(),
                child: const Text("Tutup", style: TextStyle(color: Colors.white)),
              ),
            )
          ]
        );
    }
  }
}