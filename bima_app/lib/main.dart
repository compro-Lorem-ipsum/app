import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import views
import 'views/landing_view.dart';
import 'views/take_photo_view.dart';
import 'views/verification_view.dart';
import 'views/report_patroli_view.dart';
import 'views/take_photo_patroli_view.dart';

// Import controller
import 'controllers/report_patroli_controller.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const LandingView()),
        GetPage(name: '/take-photo', page: () => const TakePhotoView()),
        GetPage(name: '/verification', page: () => const VerificationView()),
        
        GetPage(
          name: '/report-patroli', 
          page: () => const ReportPatroliView(),
          // BINDING: Ini yang membuat Controller HIDUP sebelum View dibuka
          binding: BindingsBuilder(() {
            Get.put(ReportPatroliController());
          }),
        ),

        GetPage(name: '/take-photo-patroli', page: () => const TakePhotoPatroliView()),
      ],
    );
  }
}