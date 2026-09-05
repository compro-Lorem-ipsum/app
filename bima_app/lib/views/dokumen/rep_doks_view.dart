// Tampilan halaman Dokumen Repositori.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/dokumen/rep_doks_controller.dart';
import '../../widgets/card_container.dart';

class RepDoksView extends StatelessWidget {
  const RepDoksView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const greyText = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RepDoksController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              const Text(
                'Dokumen resmi dari admin. Ketuk pada dokumen untuk langsung membuka dan membaca isinya.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator(color: primaryColor)),
                  );
                }
                if (controller.dokumen.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('Belum ada dokumen.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  );
                }
                return Column(
                  children: controller.dokumen
                      .map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDocumentCard(controller, d),
                          ))
                      .toList(),
                );
              }),
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
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Repositori Dokumen', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: primaryColor)),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(RepDoksController controller, DokumenItem item) {
    return GestureDetector(
      onTap: () => controller.openDocument(item),
      child: CardContainer(
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x33122C93)),
              ),
              child: SvgPicture.asset('assets/icons/pdf_outline.svg', width: 30, height: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.formatTanggal(item.createdAt), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  const SizedBox(height: 4),
                  Text(item.nama, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (!item.isReady) ...[
                    const SizedBox(height: 4),
                    const Text('Sedang diproses...', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: greyText)),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => controller.openDocument(item),
              child: SvgPicture.asset('assets/icons/download_icon.svg', width: 25, height: 25),
            ),
          ],
        ),
      ),
    );
  }
}
