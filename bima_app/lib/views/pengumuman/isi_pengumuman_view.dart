// Tampilan detail/isi satu pengumuman.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pengumuman/pengumuman_controller.dart';

/// Shows the announcement detail as a popup (bottom-anchored dialog with a
/// dimmed backdrop) over whichever screen is currently open, matching the
/// Figma "Isi pengumuman" modal — instead of navigating to a new full screen.
void showIsiPengumumanDialog(Map<String, dynamic> announcement) {
  Get.dialog(
    Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.75),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: const BoxDecoration(
            color: IsiPengumumanView.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IsiPengumumanView._buildDetailCard(announcement),
                  const SizedBox(height: 20),
                  IsiPengumumanView._buildTutupButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.4),
  );
}

class IsiPengumumanView extends StatelessWidget {
  const IsiPengumumanView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const disabledColor = Color(0xFF8D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PengumumanController>();
    final arguments = Get.arguments;
    final announcement = arguments is Map<String, dynamic>
        ? arguments
        : <String, dynamic>{
            'title': 'Pengumuman',
            'date': '-',
            'time': '-',
            'body': '',
            'admin': '-',
          };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(controller),
                    const SizedBox(height: 20),
                    _buildDetailCard(announcement),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
              child: _buildTutupButton(),
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
        const Text(
          'Pengumuman',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 22, color: primaryColor),
        ),
      ],
    );
  }

  static Widget _buildDetailCard(Map<String, dynamic> announcement) {
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
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                '${announcement['date']} · ${announcement['time']}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement['title'] ?? '',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: cardBorderColor),
          const SizedBox(height: 12),
          Text(
            announcement['body'] ?? '',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor, height: 1.6),
          ),
          if ((announcement['location'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: cardBorderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  announcement['location'],
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildTutupButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => Get.back(),
        child: const Text(
          'Tutup',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
