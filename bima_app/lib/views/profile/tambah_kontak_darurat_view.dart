// Tampilan tambah/ubah kontak darurat pada Profil Saya.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/profile/tambah_kontak_darurat_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/card_container.dart';
import '../../widgets/primary_button.dart';

class TambahKontakDaruratView extends GetView<TambahKontakDaruratController> {
  const TambahKontakDaruratView({super.key});

  static const dangerBg = Color(0xFFFFDDE9);
  static const dangerText = Color(0xFFF31260);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Text(
                'Tambahkan kontak darurat yang dapat dihubungi dalam keadaan mendesak.',
                style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
              ),
              const SizedBox(height: 20),
              CardContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status/Hubungan', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
                    const SizedBox(height: 8),
                    Obx(() => _HubunganField(
                          value: controller.selectedHubungan.value,
                          onTap: controller.toggleDropdown,
                        )),
                    Obx(() => controller.isDropdownOpen.value
                        ? _HubunganDropdownList(
                            options: TambahKontakDaruratController.hubunganOptions,
                            selected: controller.selectedHubungan.value,
                            onSelect: controller.selectHubungan,
                          )
                        : const SizedBox.shrink()),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Nama',
                      controller: controller.namaController,
                      hint: 'Masukan Nama',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Nomor HP',
                      controller: controller.nomorHpController,
                      hint: 'Masukan No HP',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Simpan', onPressed: controller.handleSimpan, borderRadius: 20),
              if (controller.isEdit) ...[
                const SizedBox(height: 12),
                _buildHapusButton(),
              ],
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
          onTap: controller.handleBack,
          child: SvgPicture.asset('assets/icons/arrow_left.svg', width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            controller.isEdit ? 'Ubah kontak darurat' : 'Tambah kontak darurat',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 25, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildHapusButton() {
    return GestureDetector(
      onTap: controller.handleHapus,
      child: Container(
        width: double.infinity,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: dangerBg, borderRadius: BorderRadius.circular(20)),
        child: Text('Hapus Kontak', style: AppText.semiBold.copyWith(fontSize: 16, color: dangerText)),
      ),
    );
  }
}

/// Field kosmetik yang tampil seperti AppTextField tapi jadi pemicu
/// dropdown inline "Status/Hubungan" (lihat _HubunganDropdownList).
class _HubunganField extends StatelessWidget {
  final String? value;
  final VoidCallback onTap;

  const _HubunganField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Pilih Status/Hubungan',
                style: AppText.regular.copyWith(fontSize: 12, color: value == null ? AppColors.disabled : Colors.black),
              ),
            ),
            SvgPicture.asset('assets/icons/arrow_down.svg', width: 16, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Daftar pilihan Status/Hubungan yang tampil tepat di bawah _HubunganField
/// begitu field itu di-tap, sesuai desain Figma (node 44:798).
class _HubunganDropdownList extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _HubunganDropdownList({required this.options, required this.selected, required this.onSelect});

  static const _placeholder = 'Pilih Status/Hubungan';

  @override
  Widget build(BuildContext context) {
    final items = [_placeholder, ...options];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isPlaceholder = item == _placeholder;
          final isSelected = isPlaceholder ? selected == null : selected == item;
          return GestureDetector(
            onTap: () => onSelect(isPlaceholder ? null : item),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.fieldBorder : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item, style: AppText.regular.copyWith(fontSize: 12, color: Colors.black))),
                  if (isSelected) SvgPicture.asset('assets/icons/check_dropdown_icon.svg', width: 20, height: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
