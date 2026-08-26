// Tampilan daftar Rekan Kerja.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/rekan_kerja/rekan_kerja_controller.dart';
import '../../widgets/card_container.dart';

class RekanKerjaView extends StatelessWidget {
  const RekanKerjaView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RekanKerjaController>();

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
                  _buildSubtitle(),
                  const SizedBox(height: 16),
                  Obx(() => _buildLocationBanner(controller)),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.rekan.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (controller.rekan.isEmpty) {
                  return Center(
                    child: Text('Belum ada rekan kerja.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                  itemCount: controller.rekan.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildContactCard(controller, controller.rekan[index]),
                  ),
                );
              }),
            ),
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
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        const Text('Rekan Kerja', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryColor)),
      ],
    );
  }

  Widget _buildSubtitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
        children: [
          TextSpan(text: 'Ketuk untuk hubungi rekan via '),
          TextSpan(text: 'WhatsApp', style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)),
          TextSpan(text: '. Hanya menampilkan anggota di mitra yang sama.'),
        ],
      ),
    );
  }

  Widget _buildLocationBanner(RekanKerjaController controller) {
    final clientNama = controller.clientNama.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEFFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lokasi Penugasan Anda', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              const SizedBox(height: 2),
              Text(
                clientNama.isEmpty ? '-' : clientNama,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor),
              ),
            ],
          ),
          Row(
            children: [
              SvgPicture.asset('assets/icons/building_line.svg', width: 32, height: 32),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Text('${controller.rekan.length} Rekan', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 9, color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(RekanKerjaController controller, RekanKerjaItem item) {
    return CardContainer(
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFFEBEFFF), child: Icon(Icons.person, color: primaryColor, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.role, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: item.roleColor)),
                const SizedBox(height: 2),
                Text(item.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                const SizedBox(height: 2),
                Text(item.nip, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => controller.confirmWhatsapp(item),
            child: SvgPicture.asset('assets/icons/whatsapp.svg', width: 40, height: 40),
          ),
        ],
      ),
    );
  }
}
