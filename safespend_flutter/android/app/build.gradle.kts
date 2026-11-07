import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties()
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releasePropertiesFile.exists()) {
    FileInputStream(releasePropertiesFile).use(releaseProperties::load)
}

android {
    namespace = "com.taha.safespend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.taha.safespend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Store credentials only in ignored key.properties (local) or
            // generated from encrypted CI secrets. A store build must never
            // silently fall back to the Android debug certificate.
            if (releaseTaskRequested && !releasePropertiesFile.exists()) {
                throw GradleException(
                    "Release signing is required. Create android/key.properties from " +
                        "android/key.properties.example or inject it in CI."
                )
            }
            if (releasePropertiesFile.exists()) {
                signingConfig = signingConfigs.create("release") {
                    keyAlias = releaseProperties.getProperty("keyAlias")
                    keyPassword = releaseProperties.getProperty("keyPassword")
                    storeFile = file(releaseProperties.getProperty("storeFile"))
                    storePassword = releaseProperties.getProperty("storePassword")
                }
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
