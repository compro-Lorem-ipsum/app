import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/pengajuan_controller.dart';

class BuatPengajuanView extends StatelessWidget {
  const BuatPengajuanView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const disabledColor = Color(0xFF8D8787);
  static const fieldFillColor = Color(0xFFF5F7FF);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PengajuanController>();

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
                    const Text(
                      'Ajukan Cuti atau Lembur',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Jenis Pengajuan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                    const SizedBox(height: 10),
                    Obx(() => Row(
                          children: [
                            Expanded(child: _buildJenisCard(controller, 'Lembur', 'assets/icons/clock_plus.svg')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildJenisCard(controller, 'Cuti', 'assets/icons/palm_tree.svg')),
                          ],
                        )),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDateField(context, controller, isStart: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDateField(context, controller, isStart: false)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Deskripsi/Alasan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
                    const SizedBox(height: 10),
                    _buildDescriptionField(controller),
                    const SizedBox(height: 20),
                    _buildInfoBox(),
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

  Widget _buildHeader(PengajuanController controller) {
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
          'Buat Pengajuan',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 22, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildJenisCard(PengajuanController controller, String jenis, String iconAsset) {
    final isSelected = controller.selectedJenis.value == jenis;
    return GestureDetector(
      onTap: () => controller.selectJenis(jenis),
      child: Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : cardBorderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconAsset, width: 32, height: 32),
            const SizedBox(height: 8),
            Text(jenis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, PengajuanController controller, {required bool isStart}) {
    return Obx(() {
      final date = isStart ? controller.tanggalMulai.value : controller.tanggalSelesai.value;
      return GestureDetector(
        onTap: () => isStart ? controller.pickTanggalMulai(context) : controller.pickTanggalSelesai(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStart ? 'Tanggal Mulai' : 'Tanggal Selesai',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: cardBorderColor),
              ),
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/calendar_bold.svg', width: 22, height: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date == null ? 'dd mm yyyy' : controller.formatDate(date),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: date == null ? disabledColor : Colors.black,
                      ),
                    ),
                  ),
                  SvgPicture.asset('assets/icons/arrow_down.svg', width: 16, height: 16),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDescriptionField(PengajuanController controller) {
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

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x4FFFD69E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorderColor),
      ),
      child: const Text(
        'Pengajuan Anda akan ditinjau oleh HRD dalam waktu maksimal 2x24 jam kerja. Pastikan semua data sudah benar.',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF894B00)),
      ),
    );
  }

  Widget _buildSubmitButton(PengajuanController controller) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: controller.submitPengajuan,
        child: const Text(
          'Ajukan Sekarang',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
