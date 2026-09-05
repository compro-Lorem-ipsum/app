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
import '../../services/satpam_profile_service.dart';
import '../../services/tracking_service.dart';
import '../pengumuman/pengumuman_controller.dart';
import '../pesan/pesan_controller.dart';

class LandingController extends GetxController {
  final isOnDuty = false.obs;
  final profile = Rxn<Map<String, dynamic>>();
  final workingHours = Rxn<Map<String, dynamic>>();
  final todayAttendance = Rxn<Map<String, dynamic>>();

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
    // Baca instance-nya sekali di sini supaya lazy getter di atas langsung
    // trigger fetch (fetchMessages/fetchAnnouncements) begitu Beranda dibuka,
    // bukan menunggu widget pertama yang mengaksesnya.
    pesanController;
    pengumumanController;
  }

  Future<void> refreshStatus() async {
    isOnDuty.value = await TrackingService().isOnDuty();
  }

  Future<void> loadProfile() async {
    profile.value = await SatpamProfileService().getProfile();
  }

  Future<void> loadAttendanceSummary() async {
    workingHours.value = await AttendanceSummaryService().fetchWorkingHours();
    todayAttendance.value = await AttendanceSummaryService().fetchToday();
  }

  String get displayNama => (profile.value?['nama'] as String?) ?? '-';
  String get displayNip => (profile.value?['nip'] as String?) ?? '-';

  String get displayJabatan {
    final jabatan = profile.value?['jabatan']?.toString();
    if (jabatan == null || jabatan.isEmpty) return '-';
    return jabatan[0].toUpperCase() + jabatan.substring(1);
  }

  String get displayClient => (profile.value?['client'] as String?) ?? '-';

  String get displayJamMasukShift => AttendanceSummaryService.formatJamCheckIn(todayAttendance.value);
  num? _minutes(String bucket) => (workingHours.value?[bucket] as Map?)?['minutes'] as num?;
  String get displayDurasiHariIni => AttendanceSummaryService.formatJamMenit(_minutes('today'));
  String get displayDurasiBulanIni => AttendanceSummaryService.formatJamMenit(_minutes('this_month'));
  String get displayDurasiTotal => AttendanceSummaryService.formatJamMenit(_minutes('all_time'));

  String get displayCheckIn => AttendanceSummaryService.formatJamCheckIn(todayAttendance.value);
  String get displayCheckOut => AttendanceSummaryService.formatJamCheckOut(todayAttendance.value);
  String get displayDurasiStatus => AttendanceSummaryService.formatJamMenit(todayAttendance.value?['worked_minutes'] as num?);
}
