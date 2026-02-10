import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/take_photo_patroli_controller.dart';

class TakePhotoPatroliView extends StatelessWidget {
  const TakePhotoPatroliView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(TakePhotoPatroliController());
    const primaryColor = Color(0xFF122C93);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // ================= 1. HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: const [
                  Text(
                    "Pengambilan Gambar",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w600, 
                      color: primaryColor
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ambil Gambar Lokasi Patroli",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, 
                      color: primaryColor
                    ),
                  ),
                ],
              ),
            ),

            // ================= 2. CAMERA PREVIEW (FLEXIBLE) =================
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20), 
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                clipBehavior: Clip.hardEdge, 
                child: Obx(() {
                  if (!controller.isCameraInitialized.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand, 
                    children: [
                      if (controller.photoTaken.value)
                        // Tampilan Hasil Foto
                        Image.file(
                          File(controller.photoPath.value), 
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                        )
                      else
                        // Tampilan Kamera Live
                        FittedBox(
                          fit: BoxFit.cover, 
                          child: SizedBox(
                            width: controller.cameraController!.value.previewSize!.height,
                            height: controller.cameraController!.value.previewSize!.width,
                            child: CameraPreview(controller.cameraController!),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),

            // ================= 3. TOMBOL AKSI =================
            Padding(
              padding: const EdgeInsets.all(20.0), 
              child: Obx(() => SizedBox(
                width: double.infinity,
                child: !controller.photoTaken.value
                  ? SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          )
                        ),
                        onPressed: controller.takePhoto,
                        child: const Text("Ambil Foto", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                              )
                            ),
                            onPressed: controller.usePhoto,
                            child: const Text("Gunakan Foto", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)
                              )
                            ),
                            onPressed: controller.retakePhoto,
                            child: const Text("Foto Ulang", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}