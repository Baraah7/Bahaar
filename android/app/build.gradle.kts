plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.aquanav"
    compileSdk = flutter.compileSdkVersion
    // Pin NDK version — required for reproducible OpenCV builds
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.aquanav"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ── DS-1 Vision Engine (C++ / OpenCV) ────────────────────────────────
        // Only build for real-device ABIs; emulators (x86/x86_64) lack
        // reliable OpenCL and are not a supported DS-1 target.
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // Point CMake at our cpp directory.
        // OPENCV_DIR must be set in android/local.properties:
        //   opencvSdk=/absolute/path/to/OpenCV-android-sdk
        val opencvDir = rootProject.extra.properties["opencvSdk"]
            ?.toString()
            ?.let { "$it/sdk/native/jni" }
            ?: ""   // empty string → CMake will emit a clear FATAL_ERROR

        externalNativeBuild {
            cmake {
                arguments(
                    "-DOPENCV_DIR=$opencvDir",
                    "-DANDROID_STL=c++_shared"
                )
                cppFlags("-std=c++17")
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    aaptOptions {
        noCompress += listOf("tflite")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
