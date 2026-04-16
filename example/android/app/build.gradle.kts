plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sip.baresip.baresip_flutter_example"
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
        applicationId = "com.sip.baresip.baresip_flutter_example"
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Prevent stripping of native .so files bundled inside the AAR
    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/arm64-v8a/*.so", "**/armeabi-v7a/*.so")
            useLegacyPackaging = true
        }
    }
}

repositories {
    flatDir { dirs("libs") }
}

dependencies {
    // BareSip SDK AAR — must be included directly in the host app so its
    // classes and native .so files are present at runtime
    implementation(files("libs/BareSipSdk-release.aar"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
