import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/report_patroli_controller.dart';

class ReportPatroliView extends GetView<ReportPatroliController> {
  const ReportPatroliView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF122C93);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ===== HEADER =====
              const Text(
                "Data Hasil Patroli",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              // ===== KOORDINAT =====
              Obx(() => Text(
                    controller.latitude.value != 0
                        ? "Koordinat: ${controller.latitude.value.toStringAsFixed(6)}, ${controller.longitude.value.toStringAsFixed(6)}"
                        : "Mencari lokasi...",
                    style:
                        const TextStyle(fontSize: 14, color: Colors.grey),
                  )),

              const SizedBox(height: 24),

              // ===== GRID FOTO (4 FOTO) =====
              Obx(() => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.photos.length,
                    itemBuilder: (ctx, index) {
                      final path = controller.photos[index];
                      return GestureDetector(
                        onTap: () => controller.goToCamera(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: path.isNotEmpty
                              ? Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  cacheWidth: 600,
                                )
                              : const Center(
                                  child: Text(
                                    "+",
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  )),

              const SizedBox(height: 8),
              const Text(
                "Tekan kembali jika ingin melakukan foto ulang",
                style: TextStyle(fontSize: 12, color: primaryColor),
              ),

              const SizedBox(height: 24),

              // ===== DROPDOWN SATPAM =====
              Obx(() => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Petugas",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    value: controller.selectedSatpam.value.isEmpty
                        ? null
                        : controller.selectedSatpam.value,
                    items: controller.listSatpam
                        .map<DropdownMenuItem<String>>(
                          (s) => DropdownMenuItem(
                            value: s['uuid'],
                            child: Text(s['nama']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      controller.selectedSatpam.value = val;
                      controller.fetchPos(val);
                    },
                  )),

              const SizedBox(height: 16),

              // ===== DROPDOWN POS =====
              Obx(() => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Lokasi Pos",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    value: controller.selectedPos.value.isEmpty
                        ? null
                        : controller.selectedPos.value,
                    hint: Text(
                      controller.selectedSatpam.value.isNotEmpty
                          ? "Pilih Pos"
                          : "Pilih Petugas Dulu",
                    ),
                    items: controller.listPos
                        .map<DropdownMenuItem<String>>(
                          (p) => DropdownMenuItem(
                            value: p['uuid'],
                            child: Text(p['nama']),
                          ),
                        )
                        .toList(),
                    onChanged: controller.selectedSatpam.value.isEmpty
                        ? null
                        : (val) {
                            if (val != null) {
                              controller.selectedPos.value = val;
                            }
                          },
                  )),

              const SizedBox(height: 16),

              // ===== STATUS LOKASI =====
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Status Lokasi",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: "Aman", child: Text("Aman")),
                  DropdownMenuItem(
                      value: "Tidak Aman", child: Text("Tidak Aman")),
                ],
                onChanged: (val) {
                  if (val != null) controller.status.value = val;
                },
              ),

              const SizedBox(height: 16),

              // ===== KETERANGAN =====
              TextField(
                decoration: InputDecoration(
                  labelText: "Keterangan (Opsional)",
                  hintText: "Tambahkan catatan jika ada...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                onChanged: (val) => controller.notes.value = val,
              ),

              const SizedBox(height: 32),

              // ===== SUBMIT =====
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.submitReport,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Laporkan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
