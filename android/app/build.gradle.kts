import java.util.Properties

// Этот блок читает ваши пароли из файла key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Применяем плагин Google Services
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_reflection_app"
    compileSdk = flutter.compileSdkVersion
    // Specifies the NDK version to use.
    // Use the version required by plugins to ensure compatibility.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        // Sets Java compatibility to Java 8
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.my_reflection_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Этот блок настраивает использование вашего ключа подписи
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Указываем, что для релизной сборки нужно использовать вашу подпись
            signingConfig = signingConfigs.getByName("release")
        }
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
        // Workaround for "failed to strip debug symbols" error.
        // This prevents the build from stripping symbols from native libraries.
        doNotStrip("*/armeabi-v7a/*.so")
        doNotStrip("*/arm64-v8a/*.so")
        doNotStrip("*/x86/*.so")
        doNotStrip("*/x86_64/*.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
