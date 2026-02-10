import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class TakePhotoController extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var photoTaken = false.obs;
  var photoPath = ''.obs;
  
  var latitude = ''.obs;
  var longitude = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    getLocation();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Cari kamera depan (user facing) sesuai React: facingMode: "user"
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      print("Gagal mengakses kamera: $e");
    }
  }

  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        latitude.value = position.latitude.toString();
        longitude.value = position.longitude.toString();
      }
    } catch (e) {
      print("Gagal ambil lokasi: $e");
    }
  }

  Future<void> takePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    try {
      final image = await cameraController!.takePicture();
      photoPath.value = image.path;
      photoTaken.value = true;
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  void retakePhoto() {
    photoTaken.value = false;
    photoPath.value = '';
  }

  void handleNavigate() {
    Get.toNamed('/verification', arguments: {
      'photo': photoPath.value,
      'latitude': latitude.value,
      'longitude': longitude.value,
    });
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}