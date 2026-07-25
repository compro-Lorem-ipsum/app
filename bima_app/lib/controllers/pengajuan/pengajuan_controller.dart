// Controller untuk fitur Pengajuan (cuti/izin dsb.): daftar pengajuan
// yang sudah dibuat dan proses pembuatan pengajuan baru.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/success_screen.dart';

class PengajuanController extends GetxController {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  final statusFilters = const ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  final typeFilters = const ['Semua', 'Cuti', 'Lembur'];

  final selectedStatusFilter = 'Semua'.obs;
  final selectedTypeFilter = 'Semua'.obs;

  final requests = <Map<String, dynamic>>[
    {
      'type': 'Lembur',
      'date': '31 Des 2027',
      'description': 'Pengamanan acara tahun baru',
      'status': 'Disetujui',
    },
    {
      'type': 'Cuti',
      'date': '2 Jan 2028',
      'description': 'Istirahat',
      'status': 'Disetujui',
    },
    {
      'type': 'Lembur',
      'date': '13 Feb 2027',
      'description': 'Pengamanan acara ulang tahun kantor',
      'status': 'Menunggu',
    },
    {
      'type': 'Lembur',
      'date': '13 Feb 2027',
      'description': 'Pengamanan acara tahun baru',
      'status': 'Ditolak',
    },
  ].obs;

  List<Map<String, dynamic>> get filteredRequests {
    return requests.where((r) {
      final statusMatch = selectedStatusFilter.value == 'Semua' || r['status'] == selectedStatusFilter.value;
      final typeMatch = selectedTypeFilter.value == 'Semua' || r['type'] == selectedTypeFilter.value;
      return statusMatch && typeMatch;
    }).toList();
  }

  void selectStatusFilter(String value) => selectedStatusFilter.value = value;

  void selectTypeFilter(String value) => selectedTypeFilter.value = value;

  // ===== Buat Pengajuan form state =====
  final selectedJenis = Rxn<String>();
  final tanggalMulai = Rxn<DateTime>();
  final tanggalSelesai = Rxn<DateTime>();
  final descriptionController = TextEditingController();

  void selectJenis(String jenis) => selectedJenis.value = jenis;

  String formatDate(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    );
  }

  Future<void> pickTanggalMulai(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalMulai.value ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: _datePickerTheme,
    );
    if (picked != null) tanggalMulai.value = picked;
  }

  Future<void> pickTanggalSelesai(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalSelesai.value ?? tanggalMulai.value ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: _datePickerTheme,
    );
    if (picked != null) tanggalSelesai.value = picked;
  }

  void goToBuatPengajuan() {
    selectedJenis.value = null;
    tanggalMulai.value = null;
    tanggalSelesai.value = null;
    descriptionController.clear();
    Get.toNamed('/buat-pengajuan');
  }

  void handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  void submitPengajuan() {
    if (selectedJenis.value == null) {
      Get.snackbar(
        'Jenis pengajuan belum dipilih',
        'Pilih Cuti atau Lembur.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (tanggalMulai.value == null || tanggalSelesai.value == null) {
      Get.snackbar(
        'Tanggal belum lengkap',
        'Pilih tanggal mulai dan tanggal selesai.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (tanggalSelesai.value!.isBefore(tanggalMulai.value!)) {
      Get.snackbar(
        'Tanggal tidak valid',
        'Tanggal selesai tidak boleh sebelum tanggal mulai.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Deskripsi wajib diisi',
        'Jelaskan alasan pengajuan Anda.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    requests.insert(0, {
      'type': selectedJenis.value!,
      'date': formatDate(tanggalMulai.value!),
      'description': descriptionController.text.trim(),
      'status': 'Menunggu',
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    Get.to(() => SuccessScreen(
          title: 'Pengajuan Anda Berhasil',
          buttonLabel: 'Kembali ke Beranda',
          onButtonPressed: () => Get.until((route) => route.isFirst),
        ));
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
