import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/take_photo_patroli_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/primary_button.dart';

class TakePhotoPatroliView extends StatelessWidget {
  const TakePhotoPatroliView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(TakePhotoPatroliController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ================= 1. HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    "Pengambilan Gambar",
                    textAlign: TextAlign.center,
                    style: AppText.semiBold.copyWith(fontSize: 20, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ambil Gambar Lokasi Patroli",
                    textAlign: TextAlign.center,
                    style: AppText.regular.copyWith(fontSize: 14, color: AppColors.primary),
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                clipBehavior: Clip.hardEdge,
                child: Obx(() {
                  if (!controller.isCameraInitialized.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
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
                        ? PrimaryButton(
                            label: "Ambil Foto",
                            onPressed: controller.takePhoto,
                          )
                        : Column(
                            children: [
                              PrimaryButton(
                                label: "Gunakan Foto",
                                onPressed: controller.usePhoto,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFDDE9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: controller.retakePhoto,
                                  child: Text(
                                    "Foto Ulang",
                                    style: AppText.semiBold.copyWith(color: const Color(0xFFF31260), fontSize: 16),
                                  ),
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
