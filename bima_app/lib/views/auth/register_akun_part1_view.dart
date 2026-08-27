// Tampilan langkah 1 pendaftaran akun.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_akun_part1_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/option_selector.dart';
import '../../widgets/wizard_header.dart';
import '../../widgets/wizard_scaffold.dart';

class RegisterAkunPart1View extends GetView<RegisterAkunPart1Controller> {
  const RegisterAkunPart1View({super.key});

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      header: WizardHeader(
        currentStep: controller.currentStep,
        totalSteps: controller.totalSteps,
        stepLabel: 'Data Diri',
        onBack: controller.handleBack,
        onClose: controller.handleClose,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Diri Anda', style: AppText.semiBold.copyWith(fontSize: 24, color: Colors.black)),
          const SizedBox(height: 8),
          Text(
            'Informasi dasar untuk profil personel',
            style: AppText.regular.copyWith(fontSize: 14, color: AppColors.disabled),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Nama Lengkap',
            controller: controller.namaLengkapController,
            hint: 'Masukan Nama Lengkap Anda',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'NIP',
            controller: controller.nipController,
            hint: 'Masukan NIP Anda',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Text('Jenis Kelamin', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 10),
          Obx(() => OptionSelector(
                options: controller.genderOptions,
                selected: controller.selectedGender.value,
                onSelect: controller.selectGender,
              )),
          const SizedBox(height: 24),
          Text('Asal Daerah', style: AppText.semiBold.copyWith(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 8),
          Obx(() => _AsalDaerahField(
                value: controller.selectedAsalDaerah.value,
                onTap: () => _pickAsalDaerah(context),
              )),
        ],
      ),
      buttonLabel: 'Lanjutkan',
      onButtonPressed: controller.handleLanjutkan,
    );
  }

  Future<void> _pickAsalDaerah(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AsalDaerahPickerSheet(options: controller.asalDaerahOptions),
    );
    if (selected != null) controller.selectAsalDaerah(selected);
  }
}

/// Field kosmetik yang tampil seperti AppTextField tapi dipakai sebagai
/// pemicu bottom-sheet pemilihan kabupaten/kota (bukan input teks bebas).
class _AsalDaerahField extends StatelessWidget {
  final String? value;
  final VoidCallback onTap;

  const _AsalDaerahField({required this.value, required this.onTap});

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
                value ?? 'Pilih Kota / Kabupaten Asal',
                style: AppText.regular.copyWith(fontSize: 12, color: value == null ? AppColors.disabled : Colors.black),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.disabled, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet berisi field pencarian + daftar ~514 kabupaten/kota
/// se-Indonesia (data BPS lewat package indonesia_regions) untuk field
/// "Asal Daerah" pada pendaftaran akun.
class _AsalDaerahPickerSheet extends StatefulWidget {
  final List<String> options;

  const _AsalDaerahPickerSheet({required this.options});

  @override
  State<_AsalDaerahPickerSheet> createState() => _AsalDaerahPickerSheetState();
}

class _AsalDaerahPickerSheetState extends State<_AsalDaerahPickerSheet> {
  late List<String> _filtered = widget.options;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? widget.options : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pilih Kota / Kabupaten', style: AppText.semiBold.copyWith(fontSize: 16, color: Colors.black)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: AppText.regular.copyWith(fontSize: 12, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Cari kota / kabupaten...',
                  hintStyle: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.disabled),
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.fieldBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.fieldBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text('Tidak ditemukan.', style: AppText.regular.copyWith(fontSize: 12, color: AppColors.disabled)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final name = _filtered[index];
                          return ListTile(
                            title: Text(name, style: AppText.regular.copyWith(fontSize: 13, color: Colors.black)),
                            onTap: () => Navigator.of(context).pop(name),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
