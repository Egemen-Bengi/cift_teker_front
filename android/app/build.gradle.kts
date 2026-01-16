import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")

    // FlutterFire configuration (tek sefer yeter)
    // NOTE: com.google.gms.google-services is applied conditionally below only if google-services.json exists

    // Flutter plugin en sonda olmalı
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

android {
    namespace = "com.evst.cift_teker_front"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.evst.cift_teker_front"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsKey"] = localProperties.getProperty("google.maps.key") ?: ""
    }
    

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
}

// Apply google-services plugin only if the android/app/google-services.json file exists.
// This avoids the build failure `:app:processDebugGoogleServices` when the file is missing
// (e.g., local dev environment or when the file is kept out of VCS).
val googleServicesFile = file("${project.rootDir}/android/app/google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    println("Skipping com.google.gms.google-services plugin because google-services.json was not found at ${googleServicesFile.path}")
}
