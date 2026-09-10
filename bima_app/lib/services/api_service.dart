import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'auth_service.dart';

class ApiService extends GetConnect {
  static ApiService get to => Get.find<ApiService>();

  @override
  void onInit() {
    httpClient.baseUrl = dotenv.env['BASE_API_URL'];
    httpClient.timeout = const Duration(seconds: 30);

    // Otomatis menambahkan header Authorization ke setiap request
    httpClient.addRequestModifier<dynamic>((request) async {
      final token = await AuthService().getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    // Otomatis menangkap response 401 dan mencoba me-refresh token
    httpClient.addAuthenticator<dynamic>((request) async {
      try {
        debugPrint('ApiService: Mendapat 401 Unauthorized, mencoba refresh token...');
        await AuthService().refreshToken();
        final newToken = await AuthService().getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('ApiService: Refresh token berhasil, mengulangi request...');
          request.headers['Authorization'] = 'Bearer $newToken';
        }
        return request;
      } catch (e) {
        debugPrint('ApiService: Refresh token gagal, force logout: $e');
        await AuthService().clearSession();
        // Arahkan kembali ke halaman login, hapus semua rute sebelumnya
        Get.offAllNamed('/login');
        return request;
      }
    });

    super.onInit();
  }
}
