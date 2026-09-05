// Controller untuk langkah 4 (terakhir) pendaftaran akun: membuat password
// & konfirmasi password, lalu mengirim seluruh data pendaftaran (dikumpulkan
// dari step 1-4) ke API registrasi satpam sebagai submit akhir.
//
// Avatar diunggah lewat GCS signed POST policy (dua langkah, lihat
// _uploadAvatarAndGetObjectUuid): (1) minta upload-link ke backend sendiri
// lewat POST /satpam/avatar-url, (2) POST file langsung ke bucket GCS
// pakai field-field yang dikembalikan (harus dikirim SEBELUM bagian file
// dalam body multipart — syarat dari GCS POST policy, lihat
// https://cloud.google.com/storage/docs/xml-api/post-object-forms).
// `object_uuid` hasil langkah 1 itu yang dikirim sebagai field `object_uuid`
// saat register (bukan `avatar_path`, bukan juga `path`-nya).
//
// Kalau ada masalah dengan fotonya sendiri (gagal diunggah, atau backend
// menolak lewat FACE_BAD_REQUEST karena wajah tidak terdeteksi), user
// dikembalikan ke halaman Upload PAS Foto (step 3) dengan keterangan
// error tampil inline di sana (lihat desain Figma node 44:1055) — bukan
// lewat notifikasi/snackbar di halaman ini. Error lain yang tidak
// berkaitan dengan foto (mis. NIP/email sudah terdaftar) tetap tampil di
// halaman ini karena tidak mengharuskan user mengulang upload foto.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'register_akun_upload_foto_controller.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class RegisterAkunPart4Controller extends GetxController {
  final currentStep = 4;
  final totalSteps = 4;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isSubmitting = false.obs;
  final submitStatus = ''.obs;

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

  Map<String, dynamic> _previousData = {};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _previousData = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void handleClose() {
    Get.offAllNamed('/login');
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
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

  /// Kembali ke halaman Upload PAS Foto (step 3, masih ada di bawah step
  /// 4 pada stack navigasi sehingga controller-nya tetap hidup) dan isi
  /// keterangan error di sana lewat [RegisterAkunUploadFotoController.setUploadError].
  void _returnToUploadFotoWithError(String message) {
    if (Get.isRegistered<RegisterAkunUploadFotoController>()) {
      Get.find<RegisterAkunUploadFotoController>().setUploadError(message);
    }
    Get.back();
  }

  /// Apakah respons error dari backend berarti "wajah tidak terdeteksi"
  /// pada PAS foto. Kode resminya `FACE_BAD_REQUEST`, tapi pesan mentah
  /// juga dicek (mis. "no face detected", "face not found", "wajah tidak
  /// terdeteksi") supaya variasi pesan dari backend tetap diarahkan ke
  /// halaman Upload PAS Foto, bukan ke snackbar generik.
  static bool _isNoFaceError(String? code, String? rawMessage) {
    if (code == 'FACE_BAD_REQUEST') return true;
    final msg = rawMessage?.toLowerCase() ?? '';
    if (msg.isEmpty) return false;
    if (msg.contains('no face') || msg.contains('face not') || msg.contains('face_not')) return true;
    if (msg.contains('wajah') && (msg.contains('tidak') || msg.contains('gagal'))) return true;
    return false;
  }

  /// `statusCode`/`code` dipakai untuk menerjemahkan beberapa error yang
  /// pesan mentahnya kurang jelas buat pengguna. Backend membungkusnya
  /// sebagai `{"error": {"code": ..., "message": ...}}`.
  void _showRegisterError(int? statusCode, dynamic body) {
    final error = body is Map ? body['error'] : null;
    final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();

    switch (statusCode) {
      case 409:
        _showError('Sudah Terdaftar', rawMessage ?? 'Email atau NIP ini sudah terdaftar. Gunakan yang lain.');
        return;
      case 422:
        _showError('Data Tidak Valid', rawMessage ?? 'Periksa kembali data yang Anda isi pada form pendaftaran.');
        return;
      default:
        _showError('Pendaftaran Gagal', rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.');
    }
  }

  /// Langkah 1: minta upload-link (GCS signed POST policy) dari backend.
  /// Langkah 2: POST file langsung ke bucket GCS dengan field-field yang
  /// dikembalikan. Mengembalikan `object_uuid` untuk dikirim saat register.
  Future<String> _uploadAvatarAndGetObjectUuid(String photoPath) async {
    final linkRes = await GetConnect().post('$BASE_API_URL/satpam/avatar-url', {});
    final linkOk = linkRes.statusCode != null && linkRes.statusCode! >= 200 && linkRes.statusCode! < 300;
    final linkData = linkRes.body is Map ? linkRes.body['data'] as Map<String, dynamic>? : null;
    if (!linkOk || linkData == null) {
      throw Exception('Gagal mendapatkan link upload foto.');
    }

    final objectUuid = linkData['object_uuid'] as String;
    final uploadUrl = linkData['upload_url'] as String;
    final fields = Map<String, dynamic>.from(linkData['fields'] as Map);
    final contentType = (linkData['content_type'] as String?) ?? fields['Content-Type'] as String? ?? 'image/jpeg';

    // Field-field dari GCS HARUS ditulis ke body SEBELUM bagian file — ini
    // otomatis terjamin oleh http.MultipartRequest (fields diserialisasi
    // dulu, baru files), jadi cukup pakai urutan penambahan biasa.
    final uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields.addAll(fields.map((key, value) => MapEntry(key, value.toString())))
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        photoPath,
        contentType: MediaType.parse(contentType),
      ));

    final uploadResponse = await uploadRequest.send();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception('Gagal mengunggah foto (status ${uploadResponse.statusCode}).');
    }

    return objectUuid;
  }

  Future<void> handleLanjutkan() async {
    if (isSubmitting.value) return;

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || password.length < 6) {
      _showError('Password tidak valid', 'Masukan password minimal 6 karakter.');
      return;
    }

    if (confirmPassword != password) {
      _showError('Konfirmasi password tidak sesuai', 'Pastikan konfirmasi password sama dengan password.');
      return;
    }

    final photoPath = _previousData['photoPath'] as String?;
    if (photoPath == null || photoPath.isEmpty) {
      _showError('PAS foto belum ada', 'Kembali ke langkah sebelumnya dan unggah PAS foto Anda.');
      return;
    }

    isSubmitting.value = true;
    try {
      submitStatus.value = 'Mengunggah foto...';
      final String avatarObjectUuid;
      try {
        avatarObjectUuid = await _uploadAvatarAndGetObjectUuid(photoPath);
      } catch (e) {
        debugPrint('RegisterAkunPart4Controller: gagal mengunggah foto: $e');
        _returnToUploadFotoWithError('Gagal mengunggah foto. Periksa koneksi Anda dan coba lagi.');
        return;
      }

      submitStatus.value = 'Mendaftar...';
      final payload = {
        'nama': _previousData['namaLengkap'],
        'nip': _previousData['nip'],
        'gender': _previousData['gender'],
        'asal_daerah': _previousData['asalDaerah'],
        'email': _previousData['email'],
        'nomor_hp': _previousData['phone'],
        'jabatan': _previousData['jabatan'],
        'password': password,
        'object_uuid': avatarObjectUuid,
      };

      final response = await GetConnect().post(
        '$BASE_API_URL/satpam/register',
        payload,
        headers: {'Content-Type': 'application/json'},
      );

      final body = response.body;
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;

      if (ok) {
        final data = {
          ..._previousData,
          'password': password,
        };
        Get.offNamedUntil('/register-akun-part5', (route) => route.settings.name == '/login', arguments: data);
        return;
      }

      final error = body is Map ? body['error'] : null;
      final code = error is Map ? error['code']?.toString() : null;
      final rawMessage = (error is Map ? error['message'] : (body is Map ? body['message'] : null))?.toString();
      if (_isNoFaceError(code, rawMessage)) {
        _returnToUploadFotoWithError(
          'Wajah tidak terdeteksi. Pastikan pencahayaan cukup terang dan wajah terlihat jelas tanpa masker atau kacamata gelap.',
        );
        return;
      }

      _showRegisterError(response.statusCode, body);
    } catch (e) {
      debugPrint('RegisterAkunPart4Controller: gagal mendaftar: $e');
      _showError('Pendaftaran Gagal', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
      submitStatus.value = '';
    }
  }
}
