// Tampilan halaman 'Aktifitas Saya': filter pill (Semua/Absensi/Patroli)
// dan daftar riwayat dikelompokkan per tanggal.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/aktifitas/aktifitas_saya_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/card_container.dart';

class AktifitasSayaView extends StatelessWidget {
  const AktifitasSayaView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);
  static const disabledColor = Color(0xFF8D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AktifitasSayaController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  const Text('Riwayat absensi dan patroli Anda', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  const SizedBox(height: 20),
                  const Text('Tipe', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: greyText)),
                  const SizedBox(height: 8),
                  _buildFilterPills(controller),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                    itemCount: controller.currentGroups.length,
                    itemBuilder: (context, index) => _buildGroup(controller.currentGroups[index]),
                  )),
            ),
            const BottomNavBar(active: AppTab.aktifitas),
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
        const Text('Aktifitas Saya', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryColor)),
      ],
    );
  }

  Widget _buildFilterPills(AktifitasSayaController controller) {
    return Obx(() => Row(
          children: [
            _buildPill(controller, 'Semua'),
            const SizedBox(width: 8),
            _buildPill(controller, 'Absensi'),
            const SizedBox(width: 8),
            _buildPill(controller, 'Patroli'),
          ],
        ));
  }

  Widget _buildPill(AktifitasSayaController controller, String label) {
    final isActive = controller.selectedFilter.value == label;
    return GestureDetector(
      onTap: () => controller.selectFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: isActive ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildGroup(ActivityGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.date, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
          const SizedBox(height: 12),
          ...group.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEntryCard(e),
              )),
        ],
      ),
    );
  }

  Widget _buildEntryCard(ActivityEntry entry) {
    final isAbsensi = entry.type != ActivityType.patroli;
    final iconAsset = isAbsensi ? 'assets/icons/absensi.svg' : 'assets/icons/patroli_riwayat.svg';
    final iconBg = isAbsensi ? const Color(0xFFDBEAFE) : const Color(0xFFFDEEDE);

    return CardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: SvgPicture.asset(iconAsset, width: 22, height: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Text(entry.subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              ],
            ),
          ),
          if (entry.trailing != null)
            Text(entry.trailing!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText))
          else if (entry.badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: entry.badgeBg, borderRadius: BorderRadius.circular(10)),
              child: Text(entry.badgeLabel!, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 9, color: entry.badgeColor)),
            ),
        ],
      ),
    );
  }

}
