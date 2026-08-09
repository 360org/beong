import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local dev đọc `key.properties` (gitignored); CI truyền qua biến môi trường —
// xem `.github/workflows/release.yml`.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingProperty(propertyKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey)

android {
    namespace = "net.beong.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "net.beong.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = signingProperty("storeFile", "ANDROID_KEYSTORE_PATH")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = signingProperty("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingProperty("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingProperty("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val hasReleaseKey = signingProperty("storeFile", "ANDROID_KEYSTORE_PATH") != null

            // Trên CI thì **dừng hẳn**. Nếu để rơi về debug key ở đây, cả
            // workflow vẫn xanh và AAB debug-signed đi thẳng tới Play, để Play
            // từ chối bằng một thông báo không liên quan gì tới nguyên nhân
            // ("not signed with the upload certificate"). Sai sót đáng phát hiện
            // ở phút thứ ba của build, không phải ở phút thứ mười lăm.
            if (!hasReleaseKey && System.getenv("CI") == "true") {
                throw GradleException(
                    "Build release trên CI mà không có keystore — kiểm secret " +
                        "ANDROID_KEYSTORE_BASE64 và biến ANDROID_KEYSTORE_PATH " +
                        "(xem docs/08-release-cicd.md §A-3).",
                )
            }

            // Ở máy cá nhân thì rơi về debug key là đúng: `flutter run --release`
            // chạy được ngay, không phải dựng keystore chỉ để thử bản release.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
