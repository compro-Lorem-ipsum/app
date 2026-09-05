// Controller untuk halaman Beranda: status "sedang bertugas atau tidak"
// (dibaca dari TrackingService, lihat services/tracking_service.dart)
// supaya tombol Check-in di kartu 'Status Hari ini' bisa otomatis berubah
// jadi Check-out setelah check-in berhasil; identitas satpam untuk kartu
// sapaan header (SatpamProfileService); dan ringkasan jam kerja untuk
// kartu ringkasan shift & Status Hari ini (AttendanceSummaryService).

import 'package:get/get.dart';

import '../../services/attendance_summary_service.dart';
import '../../services/satpam_profile_service.dart';
import '../../services/tracking_service.dart';

class LandingController extends GetxController {
  final isOnDuty = false.obs;
  final profile = Rxn<Map<String, dynamic>>();
  final workingHours = Rxn<Map<String, dynamic>>();
  final todayAttendance = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
    loadProfile();
    loadAttendanceSummary();
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
