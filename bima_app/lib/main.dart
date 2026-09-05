// Entry point aplikasi. Mendaftarkan seluruh routing (GetPage) dan
// binding controller-nya lewat GetMaterialApp, dikelompokkan per modul
// fitur (auth, beranda, absensi, patroli, panic, dst) yang strukturnya
// mengikuti folder lib/controllers dan lib/views.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'services/auth_service.dart';
import 'services/panic_alert_polling_service.dart';

// Import views
import 'views/auth/login_view.dart';
import 'views/auth/lupa_password_part1_view.dart';
import 'views/auth/lupa_password_part2_view.dart';
import 'views/beranda/landing_view.dart';
import 'views/patroli/report_patroli_view.dart';
import 'views/patroli/take_photo_patroli_view.dart';
import 'views/auth/register_kontak_jabatan_view.dart';
import 'views/auth/register_akun_part1_view.dart';
import 'views/auth/register_akun_upload_foto_view.dart';
import 'views/auth/register_akun_part4_view.dart';
import 'views/auth/register_akun_part5_view.dart';
import 'views/panic/panic_alert_view.dart';
import 'views/absensi/absen_checkin_view.dart';
import 'views/absensi/absen_berhasil_view.dart';
import 'views/lapor_kejadian/lapor_kejadian_view.dart';
import 'views/pengajuan/pengajuan_view.dart';
import 'views/pengajuan/buat_pengajuan_view.dart';
import 'views/pengumuman/pengumuman_view.dart';
import 'views/pesan/pesan_view.dart';
import 'views/dokumen/rep_doks_view.dart';
import 'views/rekan_kerja/rekan_kerja_view.dart';
import 'views/aktifitas/aktifitas_saya_view.dart';
import 'views/profile/profile_saya_view.dart';
import 'views/profile/tambah_kontak_darurat_view.dart';
import 'views/dokumen/unggah_berkas_view.dart';
import 'views/panic/lokasi_panic_view.dart';

// Import controller
import 'controllers/beranda/landing_controller.dart';
import 'controllers/auth/login_controller.dart';
import 'controllers/auth/lupa_password_controller.dart';
import 'controllers/patroli/report_patroli_controller.dart';
import 'controllers/auth/register_kontak_jabatan_controller.dart';
import 'controllers/auth/register_akun_part1_controller.dart';
import 'controllers/auth/register_akun_upload_foto_controller.dart';
import 'controllers/auth/register_akun_part4_controller.dart';
import 'controllers/auth/register_akun_part5_controller.dart';
import 'controllers/panic/panic_alert_controller.dart';
import 'controllers/absensi/absen_checkin_controller.dart';
import 'controllers/absensi/absen_berhasil_controller.dart';
import 'controllers/lapor_kejadian/lapor_kejadian_controller.dart';
import 'controllers/pengajuan/pengajuan_controller.dart';
import 'controllers/pengumuman/pengumuman_controller.dart';
import 'controllers/pesan/pesan_controller.dart';
import 'controllers/dokumen/rep_doks_controller.dart';
import 'controllers/rekan_kerja/rekan_kerja_controller.dart';
import 'controllers/aktifitas/aktifitas_saya_controller.dart';
import 'controllers/profile/profile_saya_controller.dart';
import 'controllers/profile/tambah_kontak_darurat_controller.dart';
import 'controllers/dokumen/unggah_berkas_controller.dart';
import 'controllers/panic/lokasi_panic_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Wajib dipanggil di isolate utama supaya bisa menerima data yang dikirim
  // dari GpsTaskHandler (lihat services/gps_task_handler.dart) yang berjalan
  // di isolate/FlutterEngine foreground service terpisah.
  FlutterForegroundTask.initCommunicationPort();

  // Kalau sesi login sebelumnya tidak dicentang "Ingat Saya", hapus di sini
  // supaya cold-start ini kembali minta login (lihat AuthService).
  await AuthService().clearSessionIfNotRemembered();
  var isLoggedIn = await AuthService().isLoggedIn();
  if (isLoggedIn) {
    // Validasi juga ke server (GET /auth/me) supaya token yang di-revoke
    // di sisi backend ketahuan walau klaim exp JWT-nya belum lewat.
    // Offline-tolerant — lihat AuthService.validateSessionWithServer().
    isLoggedIn = await AuthService().validateSessionWithServer();
  }

  // Mulai polling Panic Alert (GET /alerts/active) kalau sudah ada sesi
  // login tersimpan sejak cold-start — lihat panic_alert_polling_service.dart
  // untuk detail kenapa ini polling, bukan push. Untuk login BARU (bukan
  // sesi tersimpan), start() dipanggil dari LoginController.handleMasuk.
  if (isLoggedIn) {
    PanicAlertPollingService().start();
  }

  runApp(MyApp(initialRoute: isLoggedIn ? '/' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: initialRoute,
      smartManagement: SmartManagement.full,
      // Supaya tombol back Android meminimalkan (bukan menutup) app selama
      // foreground service GPS tracking aktif — lihat tracking_service.dart.
      builder: (context, child) => WithForegroundTask(child: child ?? const SizedBox.shrink()),
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LoginController());
          }),
        ),
        GetPage(
          name: '/lupa-password-part1',
          page: () => const LupaPasswordPart1View(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LupaPasswordController());
          }),
        ),
        GetPage(name: '/lupa-password-part2', page: () => const LupaPasswordPart2View()),

        GetPage(
          name: '/',
          page: () => const LandingView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LandingController());
          }),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        ),
        GetPage(
          name: '/report-patroli',
          page: () => const ReportPatroliView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ReportPatroliController());
          }),
        ),

        GetPage(name: '/take-photo-patroli', page: () => const TakePhotoPatroliView()),

        GetPage(
          name: '/register-kontak-jabatan',
          page: () => const RegisterKontakJabatanView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterKontakJabatanController());
          }),
        ),

        GetPage(
          name: '/register-akun-part1',
          page: () => const RegisterAkunPart1View(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterAkunPart1Controller());
          }),
        ),

        GetPage(
          name: '/register-akun-part3',
          page: () => const RegisterAkunUploadFotoView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterAkunUploadFotoController());
          }),
        ),

        GetPage(
          name: '/register-akun-part4',
          page: () => const RegisterAkunPart4View(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterAkunPart4Controller());
          }),
        ),

        GetPage(
          name: '/register-akun-part5',
          page: () => const RegisterAkunPart5View(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterAkunPart5Controller());
          }),
        ),

        GetPage(
          name: '/panic-alert',
          page: () => const PanicAlertView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PanicAlertController());
          }),
        ),

        GetPage(
          name: '/absen-checkin',
          page: () => const AbsenCheckinView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AbsenCheckinController());
          }),
        ),

        GetPage(
          name: '/absen-berhasil',
          page: () => const AbsenBerhasilView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AbsenBerhasilController());
          }),
        ),

        GetPage(
          name: '/lapor-kejadian',
          page: () => const LaporKejadianView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LaporKejadianController());
          }),
        ),

        GetPage(
          name: '/pengajuan',
          page: () => const PengajuanView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PengajuanController());
          }),
        ),

        GetPage(name: '/buat-pengajuan', page: () => const BuatPengajuanView()),

        GetPage(
          name: '/pengumuman',
          page: () => const PengumumanView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PengumumanController());
          }),
        ),

        GetPage(
          name: '/pesan',
          page: () => const PesanView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PesanController());
          }),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        ),

        GetPage(
          name: '/rep-doks',
          page: () => const RepDoksView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RepDoksController());
          }),
        ),

        GetPage(
          name: '/rekan-kerja',
          page: () => const RekanKerjaView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RekanKerjaController());
          }),
        ),

        GetPage(
          name: '/aktifitas-saya',
          page: () => const AktifitasSayaView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AktifitasSayaController());
          }),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        ),

        GetPage(
          name: '/profile-saya',
          page: () => const ProfileSayaView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ProfileSayaController());
          }),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        ),

        GetPage(
          name: '/tambah-kontak-darurat',
          page: () => const TambahKontakDaruratView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => TambahKontakDaruratController());
          }),
        ),

        GetPage(
          name: '/unggah-berkas',
          page: () => const UnggahBerkasView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => UnggahBerkasController());
          }),
        ),

        GetPage(
          name: '/lokasi-panic',
          page: () => const LokasiPanicView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LokasiPanicController());
          }),
        ),
      ],
    );
  }
}
