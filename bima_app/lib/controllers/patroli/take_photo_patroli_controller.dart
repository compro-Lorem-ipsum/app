// Controller kamera in-app (live preview) yang dipakai bersama oleh
// beberapa fitur (Laporan Patroli, Lapor Kejadian) untuk mengambil foto
// langsung dari kamera belakang device, ditampilkan live di layar.

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class TakePhotoPatroliController extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var photoTaken = false.obs;
  var photoPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Pilih kamera belakang (environment)
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      debugPrint("Error init camera: $e");
    }
  }

  Future<void> takePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    try {
      final image = await cameraController!.takePicture();
      photoPath.value = image.path;
      photoTaken.value = true;
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  void retakePhoto() {
    photoTaken.value = false;
    photoPath.value = '';
  }

  void usePhoto() {
    // Kembali ke halaman sebelumnya membawa path foto
    Get.back(result: photoPath.value);
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
