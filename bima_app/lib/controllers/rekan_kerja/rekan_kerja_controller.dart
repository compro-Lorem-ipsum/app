// Controller untuk halaman Rekan Kerja (daftar rekan satu mitra/klien),
// diambil dari GET /satpam/colleagues — rekan-rekan milik user yang sedang
// login, ditentukan backend lewat access_token (bukan uuid manual di path).
//
// Nomor kontak TIDAK ikut di daftar itu — baru diambil sesaat sebelum
// buka WhatsApp lewat GET /satpam/colleagues/:uuid (respons: { nama,
// kontak_utama }), supaya tidak perlu fetch nomor semua rekan kalau
// ujung-ujungnya cuma dipakai untuk satu orang.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

final String BASE_API_URL = dotenv.env['BASE_API_URL']!;

class RekanKerjaItem {
  final String uuid;
  final String name;
  final String nip;
  final String role;
  final Color roleColor;

  RekanKerjaItem({
    required this.uuid,
    required this.name,
    required this.nip,
    required this.role,
  }) : roleColor = _colorForRole(role);

  static Color _colorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'chief':
        return const Color(0xFFB90023);
      case 'danru':
        return const Color(0xFF894B00);
      default:
        return RekanKerjaController.primaryColor;
    }
  }
}

class RekanKerjaController extends GetxController {
  static const primaryColor = Color(0xFF122C93);

  final rekan = <RekanKerjaItem>[].obs;
  final clientNama = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchColleagues();
  }

  Future<void> fetchColleagues() async {
    isLoading.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$BASE_API_URL/satpam/colleagues',
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;

      if (data is Map) {
        clientNama.value = (data['client_nama'] ?? '').toString();
        final satpams = data['satpams'];
        if (satpams is List) {
          rekan.value = satpams.whereType<Map>().map((s) {
            return RekanKerjaItem(
              uuid: (s['uuid'] ?? '').toString(),
              name: (s['nama'] ?? '').toString(),
              nip: (s['nip'] ?? '').toString(),
              // API mengembalikan jabatan huruf kecil ('anggota'/'danru'/
              // 'chief') — kapitalkan huruf depan untuk ditampilkan.
              role: _capitalize((s['jabatan'] ?? '').toString()),
            );
          }).toList();
        }
      } else {
        debugPrint('RekanKerjaController: gagal ambil rekan kerja (status ${response.statusCode}).');
      }
    } catch (e) {
      debugPrint('RekanKerjaController: gagal ambil rekan kerja: $e');
    } finally {
      isLoading.value = false;
    }
  }

  static String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  final _isFetchingContact = false.obs;

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Ambil nomor kontak rekan lewat GET /satpam/colleagues/:uuid (baru
  /// diambil sesaat sebelum dipakai, bukan sekaligus untuk semua rekan
  /// saat memuat daftar), lalu tampilkan dialog konfirmasi WhatsApp.
  Future<void> confirmWhatsapp(RekanKerjaItem item) async {
    if (_isFetchingContact.value) return;
    _isFetchingContact.value = true;
    try {
      final token = await AuthService().getAccessToken();
      final response = await GetConnect().get(
        '$BASE_API_URL/satpam/colleagues/${item.uuid}',
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final data = ok && response.body is Map ? response.body['data'] : null;
      final kontakUtama = (data is Map ? data['kontak_utama'] : null)?.toString();

      if (kontakUtama == null || kontakUtama.trim().isEmpty) {
        _showError('Nomor Tidak Tersedia', '${item.name} belum memiliki nomor kontak.');
        return;
      }

      _showWhatsappDialog(item, kontakUtama.trim());
    } catch (e) {
      debugPrint('RekanKerjaController: gagal ambil kontak rekan kerja: $e');
      _showError('Gagal Memuat Kontak', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      _isFetchingContact.value = false;
    }
  }

  /// wa.me butuh nomor internasional tanpa '+' / '0' depan — nomor lokal
  /// yang diawali '0' diubah ke kode negara Indonesia '62'.
  String _toWhatsappNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
  }

  Future<void> _openWhatsapp(String kontakUtama) async {
    final uri = Uri.parse('https://wa.me/${_toWhatsappNumber(kontakUtama)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showError('Gagal Membuka', 'Tidak ada aplikasi WhatsApp yang terpasang.');
      }
    } catch (e) {
      debugPrint('RekanKerjaController: gagal membuka WhatsApp: $e');
      _showError('Gagal Membuka', 'Terjadi kesalahan saat membuka WhatsApp.');
    }
  }

  void _showWhatsappDialog(RekanKerjaItem item, String kontakUtama) {
    Get.dialog(
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(15)),
                    child: SvgPicture.asset('assets/icons/whatsapp.svg', width: 30, height: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text('NIP ${item.nip}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF6B6B6B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02A758),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Get.back();
                    _openWhatsapp(kontakUtama);
                  },
                  child: const Text('Buka WhatsApp', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF8D8787))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
