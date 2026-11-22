// Tampilan halaman Laporan Patroli.
// Field 'Nama Personel' kini murni tampilan (otomatis dari akun login,
// bukan dropdown), sedangkan 'Lokasi Pos' & 'Status Lokasi' tetap
// dropdown, gaya kotak putih + placeholder abu-abu sesuai desain Figma.

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patroli/report_patroli_controller.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

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

              // ===== NAMA PERSONEL (otomatis dari akun yang login) =====
              Obx(() => _buildDisplayField(
                    value: controller.personnelName.value,
                    placeholder: "Nama Personel",
                  )),

              const SizedBox(height: 16),

              // ===== LOKASI POS =====
              Obx(() => _buildDropdownField(
                    context: context,
                    floatingLabel: "Lokasi Pos",
                    hint: "Pilih Pos",
                    value: controller.selectedPos.value.isEmpty ? null : controller.selectedPos.value,
                    items: controller.listPos
                        .map<DropdownMenuItem<String>>(
                          (p) => DropdownMenuItem(value: p['uuid']?.toString(), child: Text((p['nama'] ?? '').toString())),
                        )
                        .toList(),
                    onChanged: controller.listPos.isEmpty
                        ? null
                        : (val) {
                            if (val != null) controller.selectedPos.value = val;
                          },
                  )),

              const SizedBox(height: 16),

              // ===== STATUS LOKASI =====
              Obx(() => _buildDropdownField(
                    context: context,
                    hint: "Status Lokasi",
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

  Widget _buildDisplayField({required String value, required String placeholder}) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        value.isEmpty ? placeholder : value,
        style: AppText.regular.copyWith(fontSize: 12, color: value.isEmpty ? AppColors.disabled : Colors.black),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    String? floatingLabel,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    String? selectedLabel;
    for (final item in items) {
      if (item.value == value && item.child is Text) {
        selectedLabel = (item.child as Text).data;
        break;
      }
    }

    final field = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null || items.isEmpty
          ? null
          : () => _showAdaptivePicker(
                context: context,
                title: floatingLabel ?? hint,
                currentValue: value,
                items: items,
                onSelected: onChanged,
              ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.regular.copyWith(
                  fontSize: 13,
                  color: selectedLabel == null ? AppColors.disabled : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.disabled),
          ],
        ),
      ),
    );

    if (floatingLabel == null) return field;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          field,
          Positioned(
            left: 12,
            top: -6,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                floatingLabel,
                style: AppText.regular.copyWith(fontSize: 10, color: AppColors.disabled),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdaptivePicker({
    required BuildContext context,
    required String title,
    required String? currentValue,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onSelected,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(title, style: AppText.semiBold.copyWith(fontSize: 13, color: AppColors.disabled)),
          actions: items.map((item) {
            final label = item.child is Text ? ((item.child as Text).data ?? '') : '${item.value}';
            final isSelected = item.value == currentValue;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                onSelected(item.value);
              },
              child: Text(
                label,
                style: AppText.regular.copyWith(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: AppText.semiBold.copyWith(fontSize: 16, color: const Color(0xFFA70202))),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(title, style: AppText.semiBold.copyWith(fontSize: 15, color: Colors.black)),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      final label = item.child is Text ? ((item.child as Text).data ?? '') : '${item.value}';
                      final isSelected = item.value == currentValue;
                      return ListTile(
                        title: Text(
                          label,
                          style: AppText.regular.copyWith(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : Colors.black,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary, size: 20) : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          onSelected(item.value);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
