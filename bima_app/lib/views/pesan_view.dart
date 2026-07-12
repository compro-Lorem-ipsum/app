import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pesan_controller.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/card_container.dart';

class PesanView extends StatelessWidget {
  const PesanView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);
  static const disabledColor = Color(0xFF8D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PesanController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 16, 25, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(controller),
                  const SizedBox(height: 12),
                  const Text(
                    'Pesan satu arah dari client. Isi halaman ini direset setiap pergantian shift.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMessageCard(controller, controller.messages[index]),
                    ),
                  )),
            ),
            const BottomNavBar(active: AppTab.pesan),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PesanController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Pesan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryColor)),
        ),
        Obx(() {
          if (controller.unreadCount == 0) return const SizedBox.shrink();
          return Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            child: Text(
              '${controller.unreadCount}',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageCard(PesanController controller, PesanItem item) {
    if (item.isPanic) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFFF746C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.circle, size: 10, color: Color(0xFFA70202)),
                      SizedBox(width: 6),
                      Text('Panic · Darurat', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFA70202))),
                    ],
                  ),
                  Text(item.time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                ],
              ),
              const SizedBox(height: 10),
              Text(item.sender, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
              const SizedBox(height: 6),
              Text(item.preview, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Get.toNamed('/lokasi-panic', arguments: {
                  'satpamName': item.sender,
                  'time': item.time,
                }),
                child: Row(
                  children: const [
                    Icon(Icons.location_on, size: 16, color: Color(0xFFA70202)),
                    SizedBox(width: 4),
                    Text('Tap untuk melihat lokasi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFA70202))),
                  ],
                ),
              ),
            ],
          ),
        );
    }

    return GestureDetector(
      onTap: () => controller.openMessage(item),
      child: Stack(
        children: [
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.sender, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
                    Text(item.time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.preview, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black)),
                if (item.isRead) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.done_all, size: 16, color: greyText),
                      SizedBox(width: 4),
                      Text('Dibaca', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (item.isRead)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(color: const Color(0x80F5F7FF)),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
