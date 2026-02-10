import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationController());
    const primaryColor = Color(0xFF122C93);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: const [
                  Text("Verifikasi Wajah", style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text("Pastikan Wajah dan Identitas Sesuai", style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),

              // Content Center
              Column(
                children: [
                  const Text("Konfirmasi Absensi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryColor)),
                  Text(
                    "Waktu Scan: ${TimeOfDay.now().format(context)}", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryColor)
                  ),
                  const SizedBox(height: 20),
                  
                  // Photo Preview
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 2, style: BorderStyle.solid),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi), // Mirror agar sesuai display user
                        child: Image.file(
                          File(controller.photoPath.value),
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                        ),
                      ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text("Menunggu Konfirmasi Anda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA80808),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: controller.isSubmitting.value ? null : controller.handleCancel,
                        child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Obx(() => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: controller.isSubmitting.value ? null : controller.confirmAttendance,
                        child: controller.isSubmitting.value 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Konfirmasi", style: TextStyle(fontWeight: FontWeight.w600)),
                      )),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}