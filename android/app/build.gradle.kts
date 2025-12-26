plugins {
    id("com.android.application")
    id("kotlin-android")

    // FlutterFire configuration (tek sefer yeter)
    id("com.google.gms.google-services")

    // Flutter plugin en sonda olmalı
    id("dev.flutter.flutter-gradle-plugin")
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
        minSdkVersion(23)
        targetSdkVersion(34)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
