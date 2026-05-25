plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Apply Google Services plugin so google-services.json is processed.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics") apply false
}

import java.util.*
import java.io.*

android {
    namespace = "com.example.shopsnports"
    // Explicitly set compileSdk to a value installed on the machine to avoid Gradle failures
    // (flutter.compileSdkVersion is supplied by the Flutter Gradle plugin; override if needed)
    compileSdk = 36
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
        applicationId = "com.example.shopsnports"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
    // Keep minSdk from Flutter defaults where possible; override if your app requires it
    // Use Kotlin DSL property assignment. If 'flutter.minSdkVersion' isn't an Int at
    // configuration time, replace with an explicit number (for example, 21).
    minSdk = flutter.minSdkVersion
    targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load keystore properties if present (key.properties in android/)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    buildTypes {
        release {
            // Use the release signing config when key.properties is provided.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.create("release") {
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                    storeFile = file(keystoreProperties.getProperty("storeFile"))
                    storePassword = keystoreProperties.getProperty("storePassword")
                }
            } else {
                // Fallback to debug signing if no keystore provided (development only)
                signingConfig = signingConfigs.getByName("debug")
            }

                // NOTE: temporarily disable code shrinking to avoid R8 missing/duplicate
                // class issues while local Play Core dependency resolution is adjusted.
                // For production releases, re-enable minification and ensure Play Core
                // dependencies and proguard rules are correctly configured.
                isMinifyEnabled = false
                // When minification (R8) is disabled, resource shrinking must also be disabled.
                isShrinkResources = false
                proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // Workaround for file_picker lintVitalAnalyzeRelease file lock issue
    lint {
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

// Apply Google Services to process android/app/google-services.json
// into Android resources (values.xml). Using apply() here ensures the
// plugin runs after the Android plugin configuration.
apply(plugin = "com.google.gms.google-services")
