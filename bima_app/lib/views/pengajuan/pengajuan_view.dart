// Tampilan daftar Pengajuan yang sudah dibuat.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/pengajuan/pengajuan_controller.dart';

class PengajuanView extends StatelessWidget {
  const PengajuanView({super.key});

  static const primaryColor = Color(0xFF122C93);
  static const backgroundColor = Color(0xFFF5F7FF);
  static const cardBorderColor = Color(0x1A122C93);
  static const disabledColor = Color(0xFF8D8787);
  static const fieldBorderColor = Color(0x338D8787);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PengajuanController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                    controller.loadMoreRequests();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(25, 16, 25, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(controller),
                    const SizedBox(height: 20),
                    const Text(
                      'Riwayat pengajuan cuti/lembur Anda',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Status', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: disabledColor)),
                    const SizedBox(height: 8),
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.statusFilters
                              .map((status) => _buildFilterChip(
                                    status,
                                    controller.selectedStatusFilter.value == status,
                                    () => controller.selectStatusFilter(status),
                                  ))
                              .toList(),
                        )),
                    const SizedBox(height: 16),
                    const Text('Tipe', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: disabledColor)),
                    const SizedBox(height: 8),
                    Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.typeFilters
                              .map((type) => _buildFilterChip(
                                    type,
                                    controller.selectedTypeFilter.value == type,
                                    () => controller.selectTypeFilter(type),
                                  ))
                              .toList(),
                        )),
                    const SizedBox(height: 20),
                    Obx(() {
                      final list = controller.filteredRequests;
                      if (list.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Belum ada pengajuan',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: list
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRequestCard(r),
                                ))
                            .toList(),
                      );
                    }),
                    Obx(() => controller.isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(color: primaryColor)),
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
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
        const Expanded(
          child: Text(
            'Pengajuan',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 22, color: primaryColor),
          ),
        ),
        GestureDetector(
          onTap: controller.goToBuatPengajuan,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'Buat +',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryColor : fieldBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final isLembur = request['type'] == 'Lembur';
    final status = request['status'] as String;

    Color statusBg;
    Color statusText;
    switch (status) {
      case 'Disetujui':
        statusBg = const Color(0xFFDCFCE7);
        statusText = const Color(0xFF008236);
        break;
      case 'Ditolak':
        statusBg = const Color(0xFFFFE2E2);
        statusText = const Color(0xFFC10007);
        break;
      default:
        statusBg = const Color(0xFFFEF9C2);
        statusText = const Color(0xFF894B00);
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLembur ? const Color(0xFFDBEAFE) : const Color(0xFFECD9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  isLembur ? 'assets/icons/clock_plus.svg' : 'assets/icons/palm_tree.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request['type'], style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text(request['date'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  status,
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 9, color: statusText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: cardBorderColor),
          const SizedBox(height: 8),
          Text(request['description'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: disabledColor)),
        ],
      ),
    );
  }
}
