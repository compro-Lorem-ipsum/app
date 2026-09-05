pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Dibutuhkan oleh firebase_core/firebase_messaging (push notification).
    // Plugin ini butuh android/app/google-services.json saat build — file
    // itu sengaja tidak ikut di-commit (isinya API key Firebase project
    // production), lihat catatan di android/app/build.gradle.kts.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
