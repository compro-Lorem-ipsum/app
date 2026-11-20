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

  /// True kalau sesi lokal terakhir dibuang karena shift berikutnya sudah
  /// mulai (lihat [_isStaleSession]). Dipakai display getter di bawah supaya
  /// jam check-in shift LAMA tidak ikut tampil di kartu Status Hari ini
  /// sementara tombolnya sudah balik ke "Check-in" (shift baru).
  final _sessionStale = false.obs;

  /// Tombol Check-out TIDAK punya batas waktu: selama satpam belum
  /// check-out, tombolnya tetap "Check-out" sampai shift berikutnya mulai
  /// (`starts_at` <= sekarang dan belum ada attendance-nya), baru berganti
  /// ke "Check-in". Kalau sudah check-out, kembali ke alur normal.
  Future<void> refreshStatus() async {
    var tracked = await TrackingService().isOnDuty();
    final shifts = await AttendanceSummaryService().fetchShiftsToday();
    _sessionStale.value = false;
    if (tracked && await _isLegacyFlagWithoutOpenRecord(shifts)) {
      // Flag buatan app versi lama (tanpa uuid/waktu check-in) yang nyangkut
      // setelah check-out — tidak ada record terbuka di server.
      await TrackingService().stopTracking();
      await cancelBackgroundTracking();
      tracked = false;
    }
    if (tracked && await _isAlreadyCheckedOut()) {
      // Server sudah mencatat check-out (mis. dari perangkat lain atau
      // dikoreksi admin) tapi flag lokal masih menyala.
      await TrackingService().stopTracking();
      await cancelBackgroundTracking();
      tracked = false;
    }
    if (tracked && await _isStaleSession(shifts)) {
      // Shift berikutnya sudah mulai tapi sesi lama belum di-checkout
      // (server menutupnya sebagai "partial"). Jangan biarkan Check-out
      // tampil di shift baru: check-out itu akan menutup sesi lama di server.
      await TrackingService().stopTracking();
      await cancelBackgroundTracking();
      tracked = false;
      _sessionStale.value = true;
    }
    isOnDuty.value = tracked;
  }

  /// Flag lama tidak punya `attendanceUuid` maupun `dutyStartedAt`, jadi
  /// tidak bisa diverifikasi per-record. Fallback: lihat record HARI INI —
  /// kalau sudah check-out, atau server terjangkau (ada jadwal) tapi tidak
  /// ada record terbuka, flag itu basi. Gagal memuat = tidak disimpulkan apa-apa.
  Future<bool> _isLegacyFlagWithoutOpenRecord(List<Map<String, dynamic>> shifts) async {
    if (await TrackingService().attendanceUuid() != null) return false;
    if (await TrackingService().dutyStartedAt() != null) return false;
    final record = await AttendanceSummaryService().fetchToday();
    if (record != null) return record['checked_out_at'] != null;
    return shifts.isNotEmpty;
  }

  /// Verifikasi ke server lewat GET /attendance/:uuid. Gagal memuat (offline,
  /// uuid belum tersimpan) dianggap "belum diketahui", bukan sudah check-out.
  Future<bool> _isAlreadyCheckedOut() async {
    final uuid = await TrackingService().attendanceUuid();
    if (uuid == null || uuid.isEmpty) return false;
    final record = await AttendanceSummaryService().fetchById(uuid);
    return record != null && record['checked_out_at'] != null;
  }

  /// Sesi on-duty lokal dianggap basi kalau sudah ada shift LAIN yang
  /// dimulai setelah check-in sesi itu dan shift tersebut belum punya
  /// `attendance` di server (artinya satpam belum check-in di shift itu).
  Future<bool> _isStaleSession(List<Map<String, dynamic>> shifts) async {
    final startedAt = await TrackingService().dutyStartedAt();
    if (startedAt == null) return false;
    final shift = _latestStartedShift(shifts);
    final starts = shift == null ? null : DateTime.tryParse((shift['starts_at'] ?? '').toString())?.toUtc();
    if (starts == null) return false;
    return starts.isAfter(startedAt) && shift!['attendance'] == null;
  }

  /// Shift hari ini yang `starts_at`-nya paling akhir tapi sudah lewat
  /// (<= sekarang) — dianggap shift yang sedang/baru saja dijalani.
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
  /// checkout TAPI sesinya sudah dianggap basi (lihat [_sessionStale]).
  Map<String, dynamic>? get _displayAttendance {
    final record = todayAttendance.value;
    if (record != null && record['checked_out_at'] == null && _sessionStale.value) {
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
