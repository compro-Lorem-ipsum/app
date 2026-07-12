import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lapor_kejadian_controller.dart';
import '../widgets/map_preview.dart';

class LaporKejadianView extends StatelessWidget {
  const LaporKejadianView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const disabledColor = Color(0xFF8D8787);
  static const fieldFillColor = Color(0xFFF5F7FF);
  static const fieldBorderColor = Color(0x338D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LaporKejadianController>();

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
                    _buildSectionLabel('Koordinat Lokasi'),
                    const SizedBox(height: 12),
                    _buildLocationCard(controller),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Foto Dokumentasi'),
                    const SizedBox(height: 12),
                    _buildPhotoSlots(controller),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Deskripsi Kejadian'),
                    const SizedBox(height: 12),
                    _buildDescriptionField(controller),
                    const SizedBox(height: 24),
                    _buildSubmitButton(controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LaporKejadianController controller) {
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
          'Laporan Kejadian',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 22, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
    );
  }

  Widget _buildLocationCard(LaporKejadianController controller) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Lokasi Terdeteksi Otomatis dari GPS',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
                ),
              ),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.gpsActive.value ? const Color(0xFFDCFCE7) : const Color(0xFFFFE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      controller.gpsActive.value ? 'GPS Aktif' : 'Mencari GPS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: controller.gpsActive.value ? const Color(0xFF008236) : const Color(0xFFC10007),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => MapPreview(
                latitude: controller.latitude.value,
                longitude: controller.longitude.value,
                height: 122,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lattitude', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          controller.latitude.value.toStringAsFixed(4),
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Longitude', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          controller.longitude.value.toStringAsFixed(4),
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlots(LaporKejadianController controller) {
    return Obx(() => Row(
          children: List.generate(4, (index) {
            final photoPath = controller.photos[index];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => controller.goToCamera(index),
                  child: Container(
                    height: 109,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor),
                    ),
                    child: photoPath.isEmpty
                        ? const Center(child: Icon(Icons.add, color: primaryColor, size: 22))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Image.file(File(photoPath), fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
            );
          }),
        ));
  }

  Widget _buildDescriptionField(LaporKejadianController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: TextField(
        controller: controller.descriptionController,
        maxLines: 5,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black),
        decoration: const InputDecoration(
          hintText: 'Jelaskan kejadian yang sedang terjadi',
          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(LaporKejadianController controller) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: controller.submitReport,
        child: const Text(
          'Kirim Laporan Kejadian',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
