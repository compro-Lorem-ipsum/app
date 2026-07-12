import 'package:get/get.dart';

class RegisterAkunPart5Controller extends GetxController {
  Map<String, dynamic> _previousData = {};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _previousData = Map<String, dynamic>.from(Get.arguments as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> get registeredData => _previousData;

  void handleKembaliKeLogin() {
    Get.offAllNamed('/login');
  }
}
