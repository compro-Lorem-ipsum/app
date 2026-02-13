import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/take_photo_controller.dart';

class TakePhotoView extends StatelessWidget {
  const TakePhotoView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TakePhotoController());
    const primaryColor = Color(0xFF122C93);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- HEADER ---
              Column(
                children: const [
                  Text(
                    "Forum Absensi Wajah",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Scan Wajah Anda",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // --- AREA FOTO (CORE FIX) ---
              Obx(() {
                // 1. Ambil Aspect Ratio Kamera (biasanya 4/3 atau 16/9)
                var cameraAspectRatio = controller.isCameraInitialized.value
                    ? controller.cameraController!.value.aspectRatio
                    : 1.0;

                return Column(
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge, 
                      child: Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand, 
                        children: [
                          if (!controller.photoTaken.value)
                            controller.isCameraInitialized.value
                                ? FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: 100, 
                                      height: 100 * cameraAspectRatio, 
                                      child: CameraPreview(controller.cameraController!),
                                    ),
                                  )
                                : const Center(child: CircularProgressIndicator())
                          else
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: Image.file(
                                File(controller.photoPath.value),
                                fit: BoxFit.cover, 
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),

                          // --- Overlay Guide (Oval) ---
                          if (!controller.photoTaken.value)
                            Center(
                              child: Container(
                                width: 180,
                                height: 230,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5), 
                                    width: 2
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info Lokasi
                    if (controller.photoTaken.value)
                      Column(
                        children: [
                          Text(
                            "Lokasi: ${controller.latitude}, ${controller.longitude}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Pastikan Lokasi Sudah Didapatkan",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              }),

              // --- TOMBOL AKSI ---
              Obx(() {
                return SizedBox(
                  width: 350,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: !controller.photoTaken.value
                        ? controller.takePhoto
                        : controller.handleNavigate,
                    child: Text(
                      !controller.photoTaken.value ? "Ambil Foto" : "Unggah Foto",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}