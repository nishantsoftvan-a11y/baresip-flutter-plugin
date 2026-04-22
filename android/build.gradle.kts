group = "com.sip.baresip.flutter"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.sip.baresip.flutter"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 29
    }

    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/arm64-v8a/*.so", "**/armeabi-v7a/*.so")
        }
    }
}

dependencies {
    // BareSip SDK AAR — compileOnly so the plugin compiles against it,
    // but the host app must provide it at runtime.
    // When using pub.dev package: place BareSipSdk-release.aar in your app's android/app/libs/
    // When using path dependency: the AAR in the plugin's libs/ is used
    val hostAppAar = rootProject.file("app/libs/BareSipSdk-release.aar")
    val pluginAar = file("libs/BareSipSdk-release.aar")
    val aarFile = if (hostAppAar.exists()) hostAppAar else pluginAar
    compileOnly(files(aarFile))
    // Transitive runtime deps required by the AAR
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("androidx.core:core-ktx:1.13.1")
}
