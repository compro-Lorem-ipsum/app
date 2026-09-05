plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push notification (Firebase Cloud Messaging) - plugin ini WAJIB ada
// google-services.json di folder ini kalau di-apply, tapi file itu
// sengaja tidak ikut di-commit (API key Firebase project production),
// lihat instruksi dari tim BIMA / buat project Firebase percobaan
// sendiri dengan applicationId com.example.bima_app di bawah. Supaya fitur
// LAIN (non-FCM) tetap bisa dibuild & ditest sebelum file itu tersedia,
// plugin ini HANYA diterapkan kalau filenya memang ada - begitu file
// ditaruh di sini, build berikutnya otomatis mengaktifkannya lagi tanpa
// perlu ubah kode. FcmService (lib/services/fcm_service.dart) juga
// menjaga diri sendiri lewat try/catch di sisi Dart untuk kondisi yang sama.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.example.bima_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Wajib oleh flutter_local_notifications (notifikasi Panic Alert
        // dari heartbeat WorkManager background, lihat workmanager_callback.dart).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bima_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pasangan wajib untuk isCoreLibraryDesugaringEnabled di atas.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
