import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import views
import 'views/login_view.dart';
import 'views/lupa_password_part1_view.dart';
import 'views/lupa_password_part2_view.dart';
import 'views/landing_view.dart';
import 'views/take_photo_view.dart';
import 'views/verification_view.dart';
import 'views/report_patroli_view.dart';
import 'views/take_photo_patroli_view.dart';
import 'views/register_kontak_jabatan_view.dart';
import 'views/register_akun_part1_view.dart';
import 'views/register_akun_upload_foto_view.dart';
import 'views/register_akun_part4_view.dart';
import 'views/register_akun_part5_view.dart';
import 'views/panic_alert_view.dart';
import 'views/absen_checkin_view.dart';
import 'views/absen_berhasil_view.dart';
import 'views/lapor_kejadian_view.dart';
import 'views/pengajuan_view.dart';
import 'views/buat_pengajuan_view.dart';
import 'views/pengumuman_view.dart';
import 'views/pesan_view.dart';
import 'views/rep_doks_view.dart';
import 'views/rekan_kerja_view.dart';
import 'views/aktifitas_saya_view.dart';
import 'views/profile_saya_view.dart';
import 'views/unggah_berkas_view.dart';
import 'views/lokasi_panic_view.dart';

// Import controller
import 'controllers/login_controller.dart';
import 'controllers/lupa_password_controller.dart';
import 'controllers/report_patroli_controller.dart';
import 'controllers/register_kontak_jabatan_controller.dart';
import 'controllers/register_akun_part1_controller.dart';
import 'controllers/register_akun_upload_foto_controller.dart';
import 'controllers/register_akun_part4_controller.dart';
import 'controllers/register_akun_part5_controller.dart';
import 'controllers/panic_alert_controller.dart';
import 'controllers/absen_checkin_controller.dart';
import 'controllers/absen_berhasil_controller.dart';
import 'controllers/lapor_kejadian_controller.dart';
import 'controllers/pengajuan_controller.dart';
import 'controllers/pengumuman_controller.dart';
import 'controllers/pesan_controller.dart';
import 'controllers/rep_doks_controller.dart';
import 'controllers/rekan_kerja_controller.dart';
import 'controllers/aktifitas_saya_controller.dart';
import 'controllers/profile_saya_controller.dart';
import 'controllers/unggah_berkas_controller.dart';
import 'controllers/lokasi_panic_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: '/login',
      smartManagement: SmartManagement.full,
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

        GetPage(name: '/', page: () => const LandingView()),
        GetPage(name: '/take-photo', page: () => const TakePhotoView()),
        GetPage(name: '/verification', page: () => const VerificationView()),

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
        ),

        GetPage(
          name: '/profile-saya',
          page: () => const ProfileSayaView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ProfileSayaController());
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
