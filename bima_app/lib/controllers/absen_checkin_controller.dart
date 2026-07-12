import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class AbsenCheckinController extends GetxController {
  late final bool isCheckIn;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var distanceMeter = 0.0.obs;
  var isInRadius = false.obs;
  var isLoadingLocation = true.obs;

  // Placeholder posisi Pos Utama, menunggu data mitra dari backend.
  static const double posLatitude = -6.200000;
  static const double posLongitude = 106.816666;
  static const double radiusMeter = 100;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    isCheckIn = (args is Map && args['isCheckIn'] is bool) ? args['isCheckIn'] as bool : true;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = position.latitude;
      longitude.value = position.longitude;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        posLatitude,
        posLongitude,
      );
      distanceMeter.value = distance;
      isInRadius.value = distance <= radiusMeter;
    } catch (e) {
      print("Gagal mengambil lokasi: $e");
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void refreshLocation() => _getCurrentLocation();

  void goToScan() {
    if (!isInRadius.value) return;
    Get.toNamed('/take-photo', arguments: {
      'isCheckIn': isCheckIn,
      'latitude': latitude.value.toString(),
      'longitude': longitude.value.toString(),
    });
  }
}
