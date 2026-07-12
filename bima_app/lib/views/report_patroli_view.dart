import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_patroli_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class ReportPatroliView extends GetView<ReportPatroliController> {
  const ReportPatroliView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),

              // ===== KOORDINAT =====
              Obx(() => Text(
                    controller.latitude.value != 0
                        ? "Koordinat: ${controller.latitude.value.toStringAsFixed(6)}, ${controller.longitude.value.toStringAsFixed(6)}"
                        : "Mencari lokasi...",
                    style: AppText.regular.copyWith(fontSize: 13, color: AppColors.disabled),
                  )),

              const SizedBox(height: 20),

              // ===== GRID FOTO (4 FOTO) =====
              _buildPhotoGrid(),

              const SizedBox(height: 10),
              Text(
                "Tekan kembali jika ingin melakukan foto ulang",
                textAlign: TextAlign.center,
                style: AppText.medium.copyWith(fontSize: 12, color: AppColors.primary),
              ),

              const SizedBox(height: 24),

              // ===== NAMA PERSONEL (dropdown - wired to existing selectedSatpam) =====
              Obx(() => _buildDropdownField(
                    label: "Nama Personel",
                    hint: "Pilih Personel",
                    value: controller.selectedSatpam.value.isEmpty ? null : controller.selectedSatpam.value,
                    items: controller.listSatpam
                        .map<DropdownMenuItem<String>>(
                          (s) => DropdownMenuItem(value: s['uuid'], child: Text(s['nama'])),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      controller.selectedSatpam.value = val;
                      controller.fetchPos(val);
                    },
                  )),

              const SizedBox(height: 16),

              // ===== LOKASI POS =====
              Obx(() => _buildDropdownField(
                    label: "Lokasi Pos",
                    hint: controller.selectedSatpam.value.isNotEmpty ? "Pilih Pos" : "Pilih Personel Dulu",
                    value: controller.selectedPos.value.isEmpty ? null : controller.selectedPos.value,
                    items: controller.listPos
                        .map<DropdownMenuItem<String>>(
                          (p) => DropdownMenuItem(value: p['uuid'], child: Text(p['nama'])),
                        )
                        .toList(),
                    onChanged: controller.selectedSatpam.value.isEmpty
                        ? null
                        : (val) {
                            if (val != null) controller.selectedPos.value = val;
                          },
                  )),

              const SizedBox(height: 16),

              // ===== STATUS LOKASI =====
              Obx(() => _buildDropdownField(
                    label: "Status Lokasi",
                    hint: "Pilih Status",
                    value: controller.status.value.isEmpty ? null : controller.status.value,
                    items: const [
                      DropdownMenuItem(value: "Aman", child: Text("Aman")),
                      DropdownMenuItem(value: "Tidak Aman", child: Text("Tidak Aman")),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.status.value = val;
                    },
                  )),

              const SizedBox(height: 16),

              // ===== KETERANGAN =====
              AppTextField(
                label: "Keterangan (Opsional)",
                controller: controller.notesController,
                hint: "Tambahkan catatan jika ada...",
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // ===== SUBMIT =====
              Obx(() => controller.isLoading.value
                  ? SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: null,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    )
                  : PrimaryButton(
                      label: "Kirim Laporan Patroli",
                      onPressed: controller.submitReport,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 26),
              onPressed: () => Get.back(),
            ),
          ),
          Text(
            "Laporan Patroli",
            style: AppText.semiBold.copyWith(fontSize: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Obx(() => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 8,
            childAspectRatio: 80 / 109,
          ),
          itemCount: controller.photos.length,
          itemBuilder: (ctx, index) {
            final path = controller.photos[index];
            return GestureDetector(
              onTap: () => controller.goToCamera(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                clipBehavior: Clip.hardEdge,
                child: path.isNotEmpty
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                      )
                    : const Center(
                        child: Icon(Icons.add, color: AppColors.primary, size: 22),
                      ),
              ),
            );
          },
        ));
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.disabled),
              style: AppText.regular.copyWith(fontSize: 12, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              hint: Text(hint, style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
