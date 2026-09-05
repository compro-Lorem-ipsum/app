// Controller untuk fitur Pengajuan (cuti/lembur): daftar pengajuan yang
// sudah dibuat (GET /requests) dan pembuatan pengajuan baru (POST
// /requests). Field tampilan (type/status) berbahasa Indonesia dipetakan
// dari/ke enum API (cuti|lembur, pending|accepted|rejected).

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/success_screen.dart';

final String _baseApiUrl = dotenv.env['BASE_API_URL']!;

class PengajuanController extends GetxController {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const _jenisToApi = {'Cuti': 'cuti', 'Lembur': 'lembur'};
  static const _statusFromApi = {'pending': 'Menunggu', 'accepted': 'Disetujui', 'rejected': 'Ditolak'};

  final statusFilters = const ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  final typeFilters = const ['Semua', 'Cuti', 'Lembur'];

  final selectedStatusFilter = 'Semua'.obs;
  final selectedTypeFilter = 'Semua'.obs;

  final requests = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSubmitting = false.obs;

  String? _cursor;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadRequests();
  }

  Future<Map<String, String>?> _authHeaders({bool json = false}) async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return json ? {'Content-Type': 'application/json'} : null;
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    _cursor = null;
    _hasMore = true;
    try {
      final page = await _fetchPage(cursor: null);
      requests.value = page.items;
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreRequests() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final page = await _fetchPage(cursor: _cursor);
      requests.addAll(page.items);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<({List<Map<String, dynamic>> items, String? nextCursor, bool hasMore})> _fetchPage({String? cursor}) async {
    try {
      final response = await GetConnect().get(
        '$_baseApiUrl/requests',
        query: {if (cursor != null) 'cursor': cursor},
        headers: await _authHeaders(),
      );
      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      final body = ok && response.body is Map ? response.body as Map : null;
      final data = body?['data'];
      if (data is! List) {
        debugPrint('PengajuanController: gagal memuat pengajuan (status ${response.statusCode}).');
        return (items: <Map<String, dynamic>>[], nextCursor: null, hasMore: false);
      }

      final items = data.whereType<Map>().map((item) => _fromApi(Map<String, dynamic>.from(item))).toList();
      final meta = body?['meta'] is Map ? body!['meta'] as Map : null;
      return (
        items: items,
        nextCursor: meta?['next_cursor']?.toString(),
        hasMore: meta?['has_more'] == true,
      );
    } catch (e) {
      debugPrint('PengajuanController: gagal memuat pengajuan: $e');
      return (items: <Map<String, dynamic>>[], nextCursor: null, hasMore: false);
    }
  }

  Map<String, dynamic> _fromApi(Map<String, dynamic> item) {
    final start = DateTime.tryParse((item['start_date'] ?? '').toString());
    final end = DateTime.tryParse((item['end_date'] ?? '').toString());
    final dateLabel = (start != null && end != null)
        ? (start.isAtSameMomentAs(end) ? formatDate(start) : '${formatDate(start)} - ${formatDate(end)}')
        : '-';

    return {
      'uuid': (item['uuid'] ?? '').toString(),
      'type': item['type'] == 'lembur' ? 'Lembur' : 'Cuti',
      'date': dateLabel,
      'description': (item['description'] ?? '').toString(),
      'status': _statusFromApi[item['status']] ?? 'Menunggu',
    };
  }

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

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

  void _showValidationError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> submitPengajuan() async {
    if (isSubmitting.value) return;

    final jenis = selectedJenis.value;
    if (jenis == null) {
      _showValidationError('Jenis pengajuan belum dipilih', 'Pilih Cuti atau Lembur.');
      return;
    }

    final mulai = tanggalMulai.value;
    final selesai = tanggalSelesai.value;
    if (mulai == null || selesai == null) {
      _showValidationError('Tanggal belum lengkap', 'Pilih tanggal mulai dan tanggal selesai.');
      return;
    }

    if (selesai.isBefore(mulai)) {
      _showValidationError('Tanggal tidak valid', 'Tanggal selesai tidak boleh sebelum tanggal mulai.');
      return;
    }

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      _showValidationError('Deskripsi wajib diisi', 'Jelaskan alasan pengajuan Anda.');
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await GetConnect().post(
        '$_baseApiUrl/requests',
        {
          'type': _jenisToApi[jenis],
          'description': description,
          'start_date': _isoDate(mulai),
          'end_date': _isoDate(selesai),
        },
        headers: await _authHeaders(json: true),
      );

      final ok = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
      if (ok) {
        await loadRequests();
        _showSuccessDialog();
        return;
      }

      _handleSubmitError(response.body);
    } catch (e) {
      debugPrint('PengajuanController: gagal mengirim pengajuan: $e');
      _showValidationError('Gagal Mengirim', 'Tidak dapat terhubung ke server. Periksa koneksi Anda dan coba lagi.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void _handleSubmitError(dynamic body) {
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code']?.toString() : null;
    final rawMessage = (error is Map ? error['message'] : null)?.toString();

    if (code == 'REQUEST_OVERLAP') {
      _showValidationError('Tanggal Bentrok', rawMessage ?? 'Rentang tanggal ini bentrok dengan pengajuan Anda yang lain.');
      return;
    }

    _showValidationError('Gagal Mengirim', rawMessage ?? 'Terjadi kesalahan, silakan coba lagi.');
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
