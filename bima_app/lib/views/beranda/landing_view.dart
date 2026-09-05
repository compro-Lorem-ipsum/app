// Tampilan halaman Beranda (home): ringkasan shift, tombol Panic Alert,
// grid Fitur Aplikasi, status absensi hari ini, serta daftar Pesan &
// Pengumuman terbaru.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/beranda/landing_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/card_container.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  static const panicBg = Color(0xFFFF746C);
  static const panicIconBg = Color(0xFFFFB6B2);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LandingController>();
    final features = [
      _Feature(
        'Absensi',
        'assets/icons/absensi.svg',
        () => Get.toNamed('/absen-checkin', arguments: {'isCheckIn': !controller.isOnDuty.value}),
      ),
      _Feature('Patroli', 'assets/icons/patroli.svg', () => Get.toNamed('/report-patroli')),
      _Feature('Laporan Kejadian', 'assets/icons/laporan_kejadian.svg', () => Get.toNamed('/lapor-kejadian')),
      _Feature('Pengajuan', 'assets/icons/pengajuan.svg', () => Get.toNamed('/pengajuan')),
      _Feature('Pengumuman', 'assets/icons/pengumuman.svg', () => Get.toNamed('/pengumuman')),
      _Feature('Dokumen Repositori', 'assets/icons/dokumen_repositori.svg', () => Get.toNamed('/rep-doks')),
      _Feature('Rekan Kerja', 'assets/icons/rekan_kerja.svg', () => Get.toNamed('/rekan-kerja')),
      _Feature('Pesan', 'assets/icons/pesan.svg', () => Get.toNamed('/pesan')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => _buildHeader(controller)),
                    const SizedBox(height: 20),
                    Obx(() => _buildShiftSummaryCard(controller)),
                    const SizedBox(height: 16),
                    _buildPanicAlert(),
                    const SizedBox(height: 24),
                    Text('Fitur Aplikasi', style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 12),
                    _buildFeatureGrid(features),
                    const SizedBox(height: 24),
                    Obx(() => _buildStatusHariIniCard(controller)),
                    const SizedBox(height: 24),
                    SectionHeader(title: 'Pesan', onSeeAll: () => Get.toNamed('/pesan')),
                    const SizedBox(height: 12),
                    Obx(() => _buildPesanPreview(controller)),
                    const SizedBox(height: 24),
                    SectionHeader(title: 'Pengumuman', onSeeAll: () => Get.toNamed('/pengumuman')),
                    const SizedBox(height: 12),
                    Obx(() => _buildPengumumanPreview(controller)),
                  ],
                ),
              ),
            ),
            const BottomNavBar(active: AppTab.beranda),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LandingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat Pagi', style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled)),
            const SizedBox(height: 4),
            Text(controller.displayNama, style: AppText.bold.copyWith(fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('NIP ${controller.displayNip} · ${controller.displayJabatan}', style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled)),
          ],
        ),
        GestureDetector(
          onTap: () => Get.toNamed('/profile-saya'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary, size: 30),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSummaryCard(LandingController controller) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Penempatan Mitra', style: AppText.regular.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 4),
          Text(controller.displayClient, style: AppText.semiBold.copyWith(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStat('Jam Masuk Shift', controller.displayJamMasukShift)),
              Expanded(child: _buildStat('Durasi Hari ini', controller.displayDurasiHariIni)),
            ],
          ),
          Container(margin: const EdgeInsets.symmetric(vertical: 12), height: 1, color: AppColors.cardBorder),
          Row(
            children: [
              Expanded(child: _buildStat('Bulan ini di Mitra', controller.displayDurasiBulanIni)),
              Expanded(child: _buildStat('Total di Mitra ini', controller.displayDurasiTotal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.regular.copyWith(fontSize: 12, color: Colors.black)),
        const SizedBox(height: 4),
        Text(value, style: AppText.semiBold.copyWith(fontSize: 16, color: Colors.black)),
      ],
    );
  }

  Widget _buildPanicAlert() {
    return GestureDetector(
      onTap: () => Get.toNamed('/panic-alert'),
      child: CardContainer(
        color: panicBg,
        borderColor: panicBg,
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: panicIconBg, shape: BoxShape.circle),
              child: SvgPicture.asset('assets/icons/panic_alert_icon.svg', width: 30, height: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panic Alert', style: AppText.bold.copyWith(fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tekan saat situasi darurat - Kirim ke Admin', style: AppText.regular.copyWith(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(List<_Feature> features) {
    return CardContainer(
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
        children: features.map((f) => _buildFeatureItem(f)).toList(),
      ),
    );
  }

  Widget _buildFeatureItem(_Feature feature) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(feature.iconAsset),
          ),
          const SizedBox(height: 6),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            style: AppText.regular.copyWith(fontSize: 10, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHariIniCard(LandingController controller) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Hari ini', style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x33122C93)))),
            child: Row(
              children: [
                Expanded(child: _buildStat('Check - in', controller.displayCheckIn)),
                Expanded(child: _buildStat('Check - out', controller.displayCheckOut)),
                Expanded(child: _buildStat('Durasi', controller.displayDurasiStatus)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => PrimaryButton(
                label: controller.isOnDuty.value ? 'Check - out' : 'Check - in',
                height: 45,
                onPressed: () => Get.toNamed('/absen-checkin', arguments: {'isCheckIn': !controller.isOnDuty.value}),
              )),
        ],
      ),
    );
  }

  Widget _buildPesanPreview(LandingController controller) {
    final pesanController = controller.pesanController;
    if (pesanController.isLoading.value && pesanController.messages.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (pesanController.messages.isEmpty) {
      return _buildEmptyPreview('Belum ada pesan.');
    }
    final items = pesanController.messages.take(2).toList();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildPreviewCard(
            title: items[i].title,
            time: items[i].time,
            body: items[i].preview,
            unread: !items[i].isRead,
            onTap: () => pesanController.openMessage(items[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildPengumumanPreview(LandingController controller) {
    final pengumumanController = controller.pengumumanController;
    if (pengumumanController.isLoading.value && pengumumanController.announcements.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (pengumumanController.announcements.isEmpty) {
      return _buildEmptyPreview('Belum ada pengumuman.');
    }
    final items = pengumumanController.announcements.take(2).toList();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildPreviewCard(
            title: (items[i]['title'] ?? '').toString(),
            time: '${items[i]['date']} · ${items[i]['time']}',
            body: (items[i]['summary'] ?? '').toString(),
            unread: items[i]['unread'] == true,
            onTap: () => pengumumanController.openAnnouncement(items[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyPreview(String message) {
    return CardContainer(
      child: Text(message, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
    );
  }

  Widget _buildPreviewCard({required String title, required String time, required String body, required bool unread, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (unread) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(child: Text(title, style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Text(time, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.greyText)),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  _Feature(this.label, this.iconAsset, this.onTap);
}
