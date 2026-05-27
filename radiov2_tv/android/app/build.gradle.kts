import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = sequenceOf(
    // Preferred: radiov2_tv/android/key.properties
    rootProject.file("key.properties"),
    // Fallback: use the shared keystore config from the main Android app
    // at repoRoot/android/key.properties
    rootProject.file("../../android/key.properties"),
).firstOrNull { it.exists() }

if (keyPropertiesFile != null) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

fun keyProp(name: String): String? = keyProperties.getProperty(name)

val hasReleaseSigning =
    !keyProp("keyAlias").isNullOrBlank() &&
        !keyProp("keyPassword").isNullOrBlank() &&
        !keyProp("storeFile").isNullOrBlank() &&
        !keyProp("storePassword").isNullOrBlank()

android {
    namespace = "com.example.radiov2_tv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.radiov2_tv"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keyProp("keyAlias")!!
                keyPassword = keyProp("keyPassword")!!
                storeFile = file(keyProp("storeFile")!!)
                storePassword = keyProp("storePassword")!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }

    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output.outputFileName = "RadioV2-TV.apk"
        }
    }
}

flutter {
    source = "../.."
}
