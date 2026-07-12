import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lokasi_panic_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/card_container.dart';
import '../widgets/map_preview.dart';

class LokasiPanicView extends StatelessWidget {
  const LokasiPanicView({super.key});

  static const backgroundColor = Color(0xFFFFF0F0);
  static const panicRed = Color(0xFFA70202);
  static const panicBorder = Color(0xFFFF746C);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LokasiPanicController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSatpamCard(controller),
              const SizedBox(height: 16),
              _buildMapCard(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back, color: panicRed, size: 28),
        ),
        const SizedBox(width: 12),
        Text('Lokasi Panic', style: AppText.semiBold.copyWith(fontSize: 25, color: panicRed)),
      ],
    );
  }

  Widget _buildSatpamCard(LokasiPanicController controller) {
    return CardContainer(
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: Color(0xFFEBEFFF), child: Icon(Icons.person, color: AppColors.primary, size: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.satpamName, style: AppText.semiBold.copyWith(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 2),
                Text('${controller.nip} · ${controller.mitra}', style: AppText.regular.copyWith(fontSize: 12, color: AppColors.greyText)),
              ],
            ),
          ),
          Text(controller.time, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.greyText)),
        ],
      ),
    );
  }

  Widget _buildMapCard(LokasiPanicController controller) {
    return CardContainer(
      borderColor: panicBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapPreview(
            latitude: controller.latitude,
            longitude: controller.longitude,
            height: 140,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latitude', style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
                    const SizedBox(height: 4),
                    Text(
                      controller.latitude.toStringAsFixed(4),
                      style: AppText.medium.copyWith(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Longitude', style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
                    const SizedBox(height: 4),
                    Text(
                      controller.longitude.toStringAsFixed(4),
                      style: AppText.medium.copyWith(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
