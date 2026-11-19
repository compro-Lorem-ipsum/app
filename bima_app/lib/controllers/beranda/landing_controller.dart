// Controller untuk halaman Beranda: status "sedang bertugas atau tidak"
// (dibaca dari TrackingService, lihat services/tracking_service.dart)
// supaya tombol Check-in di kartu 'Status Hari ini' bisa otomatis berubah
// jadi Check-out setelah check-in berhasil; identitas satpam untuk kartu
// sapaan header (SatpamProfileService); dan ringkasan jam kerja untuk
// kartu ringkasan shift & Status Hari ini (AttendanceSummaryService).
//
// Preview "Pesan" & "Pengumuman" memakai instance PesanController /
// PengumumanController yang SAMA dengan halaman masing-masing (bukan
// fetch terpisah) — dulu kartu ini teks statis (placeholder), sehingga
// tap tidak menampilkan apa pun dan status baca tidak pernah berubah.
// Dengan berbagi instance yang sama, status baca yang diubah dari sini
// otomatis konsisten dengan halaman Pesan/Pengumuman itu sendiri.

import 'package:get/get.dart';

import '../../services/attendance_summary_service.dart';
import '../../services/documents_service.dart';
import '../../services/satpam_profile_service.dart';
import '../../services/tracking_service.dart';
import '../../services/workmanager_callback.dart';
import '../pengumuman/pengumuman_controller.dart';
import '../pesan/pesan_controller.dart';

class LandingController extends GetxController {
  final isOnDuty = false.obs;
  final profile = Rxn<Map<String, dynamic>>();
  final workingHours = Rxn<Map<String, dynamic>>();
  final todayAttendance = Rxn<Map<String, dynamic>>();

  /// Null = belum diketahui (anggap seperti belum lengkap, jangan
  /// sembunyikan titik merah); false = belum lengkap; true = lengkap.
  /// Dipakai avatar di header Beranda — lihat _buildHeader di landing_view.dart.
  final documentsComplete = Rxn<bool>();

  late final PesanController pesanController = Get.isRegistered<PesanController>()
      ? Get.find<PesanController>()
      : Get.put(PesanController(), permanent: true);

  late final PengumumanController pengumumanController = Get.isRegistered<PengumumanController>()
      ? Get.find<PengumumanController>()
      : Get.put(PengumumanController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
    loadProfile();
    loadAttendanceSummary();
    loadDocumentsStatus();
    // Baca instance-nya sekali di sini supaya lazy getter di atas langsung
    // trigger fetch (fetchMessages/fetchAnnouncements) begitu Beranda dibuka,
    // bukan menunggu widget pertama yang mengaksesnya.
    pesanController;
    pengumumanController;
  }

  Future<void> loadDocumentsStatus() async {
    documentsComplete.value = await DocumentsService().isComplete();
  }

  /// Dipakai pull-to-refresh di landing_view.dart — menyegarkan semua
  /// data kartu Beranda sekaligus, termasuk preview Pesan & Pengumuman
  /// (lewat instance controller yang sama, lihat komentar di atas kelas ini).
  /// Nama sengaja bukan `refresh()` polos — itu nama method (@protected)
  /// bawaan GetxController buat notify GetBuilder, beda arti di sini.
  Future<void> refreshAll() async {
    await Future.wait([
      refreshStatus(),
      loadProfile(),
      loadAttendanceSummary(),
      loadDocumentsStatus(),
      pesanController.refreshAll(),
      pengumumanController.fetchAnnouncements(),
    ]);
  }

  /// True kalau batas toleransi check-out (lihat [_checkoutGrace]) untuk
  /// shift terakhir sudah lewat. Dipakai juga oleh display getter di bawah
  /// supaya jam check-in shift yang sudah "dianggap lewat" itu tidak ikut
  /// ditampilkan di kartu Status Hari ini — kalau tombolnya sudah balik ke
  /// "Check-in" (shift baru), menampilkan jam check-in shift LAMA di
  /// sampingnya cuma membingungkan pengguna (terlihat seperti kontradiksi).
  final _checkoutGraceExpired = false.obs;

  Future<void> refreshStatus() async {
    var tracked = await TrackingService().isOnDuty();
    final shifts = await AttendanceSummaryService().fetchShiftsToday();
    if (tracked && await _isStaleSession(shifts)) {
      // Sesi lokal berasal dari shift yang sudah lewat & tidak pernah
      // di-checkout (mis. 18 Nov lupa/gagal check-out, lalu server menutup
      // otomatis jadi "partial"). Jangan biarkan tombol Check-out tampil
      // di shift baru: check-out itu akan menutup sesi lama di server.
      await TrackingService().stopTracking();
      await cancelBackgroundTracking();
      tracked = false;
    }
    _checkoutGraceExpired.value = _isPastCheckoutGrace(shifts);
    isOnDuty.value = tracked && !_checkoutGraceExpired.value;
  }

  static const _maxDutyDuration = Duration(hours: 12);

  /// Sesi on-duty lokal dianggap basi kalau sudah ada shift LAIN yang
  /// dimulai setelah check-in sesi itu dan shift tersebut belum punya
  /// `attendance` di server (artinya satpam belum check-in di shift itu).
  Future<bool> _isStaleSession(List<Map<String, dynamic>> shifts) async {
    final startedAt = await TrackingService().dutyStartedAt();
    if (startedAt == null) return false;
    // Shift maksimal 8 jam + toleransi/penutupan otomatis server (~2,25 jam
    // setelah shift berakhir). Lewat batas ini sesi pasti sudah ditutup
    // server, walau shift berikutnya belum mulai (jendela check-in baru
    // buka 1 jam sebelum shift).
    if (DateTime.now().toUtc().difference(startedAt) > _maxDutyDuration) return true;
    final shift = _latestStartedShift(shifts);
    final starts = shift == null ? null : DateTime.tryParse((shift['starts_at'] ?? '').toString())?.toUtc();
    if (starts == null) return false;
    return starts.isAfter(startedAt) && shift!['attendance'] == null;
  }

  /// Toleransi check-out: 60 menit setelah shift berakhir. Dipakai supaya
  /// tombol Check-out shift SEBELUMNYA tidak nyangkut selamanya kalau lupa
  /// checkout — lewat batas ini, Beranda balik tampil "Check-in" (untuk
  /// shift selanjutnya) walau flag lokal TrackingService.isOnDuty masih
  /// true. Dalam batas ini, "Check-out" tetap tampil selama belum checkout.
  static const _checkoutGrace = Duration(minutes: 60);

  bool _isPastCheckoutGrace(List<Map<String, dynamic>> shifts) {
    final shift = _latestStartedShift(shifts);
    final ends = shift == null ? null : DateTime.tryParse((shift['ends_at'] ?? '').toString())?.toUtc();
    if (ends == null) return false;
    return DateTime.now().toUtc().isAfter(ends.add(_checkoutGrace));
  }

  /// Shift hari ini yang `starts_at`-nya paling akhir tapi sudah lewat
  /// (<= sekarang) — dianggap shift yang sedang/baru saja dijalani, dipakai
  /// hanya untuk ambil `ends_at` di atas.
  Map<String, dynamic>? _latestStartedShift(List<Map<String, dynamic>> shifts) {
    final now = DateTime.now().toUtc();
    Map<String, dynamic>? latest;
    DateTime? latestStart;
    for (final shift in shifts) {
      final starts = DateTime.tryParse((shift['starts_at'] ?? '').toString())?.toUtc();
      if (starts == null || starts.isAfter(now)) continue;
      if (latestStart == null || starts.isAfter(latestStart)) {
        latest = shift;
        latestStart = starts;
      }
    }
    return latest;
  }

  Future<void> loadProfile() async {
    profile.value = await SatpamProfileService().getProfile();
  }

  Future<void> loadAttendanceSummary() async {
    workingHours.value = await AttendanceSummaryService().fetchWorkingHours();
    todayAttendance.value = await AttendanceSummaryService().fetchToday();
  }

  String get displayNama => (profile.value?['nama'] as String?) ?? '-';
  String? get avatarUrl => profile.value?['avatar_url'] as String?;
  String get displayNip => (profile.value?['nip'] as String?) ?? '-';

  String get displayJabatan {
    final jabatan = profile.value?['jabatan']?.toString();
    if (jabatan == null || jabatan.isEmpty) return '-';
    return jabatan[0].toUpperCase() + jabatan.substring(1);
  }

  String get displayClient => (profile.value?['client'] as String?) ?? '-';

  /// Record hari ini untuk ditampilkan — null-kan kalau shift-nya belum
  /// checkout TAPI batas toleransi check-out sudah lewat (lihat
  /// [_checkoutGraceExpired]), supaya jam check-in shift yang sudah
  /// dianggap lewat tidak nyangkut di kartu sementara tombolnya sendiri
  /// sudah balik ke "Check-in".
  Map<String, dynamic>? get _displayAttendance {
    final record = todayAttendance.value;
    if (record != null && record['checked_out_at'] == null && _checkoutGraceExpired.value) {
      return null;
    }
    return record;
  }

  String get displayJamMasukShift => AttendanceSummaryService.formatJamCheckIn(_displayAttendance);
  num? _minutes(String bucket) => (workingHours.value?[bucket] as Map?)?['minutes'] as num?;
  String get displayDurasiHariIni => AttendanceSummaryService.formatJamMenit(_minutes('today'));
  String get displayDurasiBulanIni => AttendanceSummaryService.formatJamMenit(_minutes('this_month'));
  String get displayDurasiTotal => AttendanceSummaryService.formatJamMenit(_minutes('all_time'));

  String get displayCheckIn => AttendanceSummaryService.formatJamCheckIn(_displayAttendance);
  String get displayCheckOut => AttendanceSummaryService.formatJamCheckOut(_displayAttendance);
  String get displayDurasiStatus => AttendanceSummaryService.formatJamMenit(_displayAttendance?['worked_minutes'] as num?);
}
