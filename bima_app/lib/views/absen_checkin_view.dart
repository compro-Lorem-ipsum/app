import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/absen_checkin_controller.dart';
import '../widgets/card_container.dart';
import '../widgets/map_preview.dart';

class AbsenCheckinView extends StatelessWidget {
  const AbsenCheckinView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const disabledColor = Color(0xFF8D8787);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);
  static const radiusBlueBg = Color(0xFFDBEAFE);
  static const radiusBlueText = Color(0xFF122C93);
  static const radiusRedBg = Color(0xFFFFE2E2);
  static const radiusRedText = Color(0xFFA70202);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AbsenCheckinController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller),
              const SizedBox(height: 20),
              _buildSatpamCard(),
              const SizedBox(height: 16),
              _buildLocationCard(controller),
              const SizedBox(height: 16),
              _buildVerifikasiCard(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbsenCheckinController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        Text(
          controller.isCheckIn ? 'Chek in' : 'Chek out',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 25,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSatpamCard() {
    return CardContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Satpam', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
              SizedBox(height: 4),
              Text('NIP 123xxx', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
              SizedBox(height: 2),
              Text('Shift Pagi 07:00 - 17:00', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(AbsenCheckinController controller) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('LOKASI', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: primaryColor)),
                  Text(' · OTOMATIS DARI GPS', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: greyText)),
                ],
              ),
              _buildRadiusPill(controller),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pos Utama - Nama Mitra',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Obx(() => MapPreview(
                latitude: controller.latitude.value,
                longitude: controller.longitude.value,
              )),
          const SizedBox(height: 6),
          Obx(() {
            if (controller.isLoadingLocation.value) {
              return const Text('Mencari lokasi...', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText));
            }
            final lat = controller.latitude.value.toStringAsFixed(6);
            final lng = controller.longitude.value.toStringAsFixed(6);
            final suffix = controller.isInRadius.value
                ? '${controller.distanceMeter.value.toStringAsFixed(0)} meter dari Pos'
                : 'Diluar Radius Pos';
            return Text(
              '$lat, $lng · $suffix',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRadiusPill(AbsenCheckinController controller) {
    return Obx(() {
      final inRadius = controller.isInRadius.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: inRadius ? radiusBlueBg : radiusRedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          inRadius ? 'Dalam Radius' : 'Diluar Radius',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 9,
            color: inRadius ? radiusBlueText : radiusRedText,
          ),
        ),
      );
    });
  }

  Widget _buildVerifikasiCard(AbsenCheckinController controller) {
    return Container(
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
          const Text('Verifikasi Wajah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: primaryColor)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 190,
              height: 230,
              child: CustomPaint(
                painter: _DashedOvalPainter(color: greyText.withValues(alpha: 0.5)),
                child: const Center(
                  child: Icon(Icons.face_retouching_natural, size: 56, color: greyText),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Posisikan wajah di dalam bingkai oval',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontStyle: FontStyle.italic, fontSize: 12, color: greyText),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final enabled = controller.isInRadius.value && !controller.isLoadingLocation.value;
            return SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? primaryColor : disabledColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: enabled ? controller.goToScan : null,
                child: const Text('Pindai Wajah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  final Color color;
  const _DashedOvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOvalPainter oldDelegate) => oldDelegate.color != color;
}
