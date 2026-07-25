// Tampilan daftar Pengumuman.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pengumuman/pengumuman_controller.dart';

class PengumumanView extends StatelessWidget {
  const PengumumanView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const disabledColor = Color(0xFF8D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PengumumanController>();

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
                  _buildHeader(controller),
                  const SizedBox(height: 20),
                  const Text(
                    'Pengumuman resmi dari admin PT Bima Global. Tap untuk membaca lengkap.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                    itemCount: controller.announcements.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAnnouncementCard(controller, controller.announcements[index]),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PengumumanController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.handleBack,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_back, size: 26, color: primaryColor),
          ),
        ),
        const Expanded(
          child: Text(
            'Pengumuman',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 22, color: primaryColor),
          ),
        ),
        Obx(() {
          final count = controller.unreadCount;
          if (count == 0) return const SizedBox.shrink();
          return Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            child: Text(
              '$count',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnnouncementCard(PengumumanController controller, Map<String, dynamic> announcement) {
    final isUnread = announcement['unread'] == true;
    return GestureDetector(
      onTap: () => controller.openAnnouncement(announcement),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                Text('${announcement['date']} · ${announcement['time']}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
                const Spacer(),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement['title'], style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              announcement['summary'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: cardBorderColor),
            const SizedBox(height: 8),
            Text(announcement['admin'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
          ],
        ),
      ),
    );
  }
}
