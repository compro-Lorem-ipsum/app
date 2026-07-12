import 'package:flutter/material.dart';
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
        Get.toNamed('/aktifitas-saya');
        break;
      case AppTab.pesan:
        Get.toNamed('/pesan');
        break;
      case AppTab.profile:
        Get.toNamed('/profile-saya');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      child: Row(
        children: [
          Expanded(child: _item(Icons.home, 'Beranda', AppTab.beranda)),
          Expanded(child: _item(Icons.history, 'Aktifitas', AppTab.aktifitas)),
          Expanded(child: _item(Icons.chat_bubble_outline, 'Pesan', AppTab.pesan)),
          Expanded(child: _item(Icons.person_outline, 'Profile', AppTab.profile)),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, AppTab tab) {
    final isActive = tab == active;
    final color = isActive ? AppColors.primary : AppColors.disabled;
    return GestureDetector(
      onTap: () => _go(tab),
      child: Container(
        decoration: isActive
            ? const BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 3)))
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
