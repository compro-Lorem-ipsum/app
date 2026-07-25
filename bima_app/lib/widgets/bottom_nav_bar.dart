// Bottom navigation bar (Beranda/Aktifitas/Pesan/Profile).
// Indikator biru di atas tab aktif bergeser dengan animasi sliding
// (AnimatedAlign) mengikuti tab yang dipilih, dan setiap tab berpindah
// halaman dengan offAllNamed agar tidak menumpuk riwayat navigasi.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'app_theme.dart';

enum AppTab { beranda, aktifitas, pesan, profile }

class BottomNavBar extends StatelessWidget {
  final AppTab active;

  const BottomNavBar({super.key, required this.active});

  void _go(AppTab tab) {
    if (tab == active) return;
    switch (tab) {
      case AppTab.beranda:
        Get.offAllNamed('/');
        break;
      case AppTab.aktifitas:
        Get.offAllNamed('/aktifitas-saya');
        break;
      case AppTab.pesan:
        Get.offAllNamed('/pesan');
        break;
      case AppTab.profile:
        Get.offAllNamed('/profile-saya');
        break;
    }
  }

  static const _tabs = AppTab.values;
  static const _animDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexOf(active);
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      child: Stack(
        children: [
          // Indikator biru yang sliding mengikuti tab aktif.
          AnimatedAlign(
            duration: _animDuration,
            curve: Curves.easeOut,
            alignment: Alignment(2 * index / (_tabs.length - 1) - 1, -1),
            child: FractionallySizedBox(
              widthFactor: 1 / _tabs.length,
              child: Container(height: 3, color: AppColors.primary),
            ),
          ),
          Row(
            children: [
              Expanded(child: _item('assets/icons/nav_beranda.svg', 'Beranda', AppTab.beranda)),
              Expanded(child: _item('assets/icons/nav_aktifitas.svg', 'Aktifitas', AppTab.aktifitas)),
              Expanded(child: _item('assets/icons/nav_pesan.svg', 'Pesan', AppTab.pesan)),
              Expanded(child: _item('assets/icons/nav_profile.svg', 'Profile', AppTab.profile)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String iconAsset, String label, AppTab tab) {
    final isActive = tab == active;
    final color = isActive ? AppColors.primary : AppColors.disabled;
    return GestureDetector(
      onTap: () => _go(tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<Color?>(
            duration: _animDuration,
            tween: ColorTween(begin: color, end: color),
            builder: (context, animatedColor, _) => SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(animatedColor ?? color, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: _animDuration,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: color),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
