// Tampilan halaman Profil Saya.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/profile/profile_saya_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/card_container.dart';

class ProfileSayaView extends StatelessWidget {
  const ProfileSayaView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);
  static const disabledColor = Color(0xFF8D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileSayaController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    Obx(() => _buildProfileCard(controller)),
                    const SizedBox(height: 12),
                    Obx(() => _buildStatsCard(controller)),
                    const SizedBox(height: 12),
                    Obx(() => _buildDocumentsBanner(controller)),
                    const SizedBox(height: 20),
                    const Text('Data Personel', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 8),
                    Obx(() => _buildDataPersonelCard(controller)),
                    const SizedBox(height: 20),
                    const Text('Penugasan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 8),
                    Obx(() => _buildPenugasanCard(controller)),
                    const SizedBox(height: 20),
                    const Text('Kontak', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 8),
                    Obx(() => _buildKontakCard(controller)),
                    const SizedBox(height: 20),
                    const Text('Kontak Darurat', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 8),
                    Obx(() => _buildKontakDaruratCard(controller)),
                    const SizedBox(height: 20),
                    _buildLogoutButton(controller),
                  ],
                ),
              ),
            ),
            const BottomNavBar(active: AppTab.profile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: SvgPicture.asset('assets/icons/arrow_left.svg', width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        const Text('Profil Saya', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryColor)),
      ],
    );
  }

  Widget _buildProfileCard(ProfileSayaController controller) {
    return CardContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEBEFFF),
            backgroundImage: (controller.displayAvatarUrl?.isNotEmpty ?? false) ? NetworkImage(controller.displayAvatarUrl!) : null,
            onBackgroundImageError: (controller.displayAvatarUrl?.isNotEmpty ?? false) ? (_, _) {} : null,
            child: (controller.displayAvatarUrl?.isNotEmpty ?? false) ? null : const Icon(Icons.person, color: primaryColor, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.displayNama, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Text('${controller.displayJabatan} · NIP ${controller.displayNip}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
            child: const Text('Aktif', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 9, color: Color(0xFF008236))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ProfileSayaController controller) {
    return CardContainer(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildClockStat('Hari ini', controller.displayDurasiHariIni, controller.displayCheckInHariIniCaption)),
            const VerticalDivider(color: cardBorderColor, width: 24, thickness: 1),
            Expanded(child: _buildClockStat('Semua Waktu', controller.displayDurasiSemuaWaktu, controller.displaySejak)),
          ],
        ),
      ),
    );
  }

  Widget _buildClockStat(String label, String value, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset('assets/icons/clock_icon.svg', width: 14, height: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: primaryColor)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black)),
        const SizedBox(height: 4),
        Text(caption, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: greyText)),
      ],
    );
  }

  Widget _buildDocumentsBanner(ProfileSayaController controller) {
    final complete = controller.documentsComplete.value;
    final bg = complete ? const Color(0xFFDBEAFE) : const Color(0xFFFFD2D0);
    final border = complete ? const Color(0xFF93C5FD) : const Color(0xFFE8536F);
    final iconBg = complete ? const Color(0xFFDBEAFE) : const Color(0xFFFFBCBC);
    final iconColor = complete ? primaryColor : AppColors.danger;

    return GestureDetector(
      onTap: controller.openDocuments,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/dokumen_text.svg',
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complete ? 'Dokumen Lengkap' : 'Lengkapi Dokumen',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complete
                        ? 'Terima kasih! Dokumen Anda sudah lengkap dan seluruh fitur akun telah aktif.'
                        : 'Mohon lengkapi dokumen Anda untuk mengaktifkan seluruh fitur akun.',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/icons/chevron_right.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPersonelCard(ProfileSayaController controller) {
    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInfoRow('assets/icons/nip_icon.svg', 'NIP', controller.displayNip),
          _buildInfoRow('assets/icons/nrg_icon.svg', 'NRG', controller.displayNrg),
          _buildInfoRow('assets/icons/pangkat_icon.svg', 'Pangkat', controller.displayJabatan),
          _buildInfoRow('assets/icons/gender_male_icon.svg', 'Jenis Kelamin', controller.displayGender),
          _buildInfoRow('assets/icons/location_icon.svg', 'Asal Daerah', controller.displayAsalDaerah, isLast: true, iconWidth: 16),
        ],
      ),
    );
  }

  Widget _buildPenugasanCard(ProfileSayaController controller) {
    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildStackedInfoRow('assets/icons/mitra_icon.svg', 'Mitra', controller.displayClient),
          _buildStackedInfoRow('assets/icons/penempatan_icon.svg', 'Tanggal Penempatan', controller.displayDateAssigned, isLast: true),
        ],
      ),
    );
  }

  Widget _buildStackedInfoRow(String iconAsset, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: cardBorderColor)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, width: 22, height: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKontakCard(ProfileSayaController controller) {
    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInfoRow('assets/icons/telp_icon.svg', 'No. Telp', controller.displayKontakUtama),
          _buildInfoRow('assets/icons/email_icon.svg', 'Email', controller.displayEmail, isLast: true),
        ],
      ),
    );
  }

  Widget _buildKontakDaruratCard(ProfileSayaController controller) {
    final list = controller.kontakDaruratList;
    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final data in list) _buildKontakDaruratRow(data, onTap: () => controller.openKontakDarurat(existing: data)),
          if (list.length < ProfileSayaController.maxKontakDarurat) _buildTambahKontakDaruratRow(controller),
        ],
      ),
    );
  }

  Widget _buildKontakDaruratRow(Map<String, dynamic> data, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cardBorderColor))),
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/telp_icon.svg', width: 22, height: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: data['nama'] ?? '',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
                        ),
                        TextSpan(
                          text: '  (${data['hubungan'] ?? ''})',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['nomorHp'] ?? '',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/icons/kontak_darurat_chevron.svg',
              width: 12,
              height: 24,
              colorFilter: const ColorFilter.mode(greyText, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTambahKontakDaruratRow(ProfileSayaController controller) {
    return GestureDetector(
      onTap: () => controller.openKontakDarurat(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/add_circle_icon.svg', width: 20, height: 20),
            const SizedBox(width: 6),
            const Text('Tambah Kontak Darurat', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String iconAsset, String label, String value, {bool bold = false, bool isLast = false, double iconWidth = 22}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: cardBorderColor)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, width: iconWidth, height: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: bold ? greyText : Colors.black),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ProfileSayaController controller) {
    return GestureDetector(
      onTap: controller.logout,
      child: Container(
        width: double.infinity,
        height: 57,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFFDDE9), borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/logout_icon.svg', width: 22, height: 22),
            const SizedBox(width: 8),
            const Text('Keluar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFFF31260))),
          ],
        ),
      ),
    );
  }

}
