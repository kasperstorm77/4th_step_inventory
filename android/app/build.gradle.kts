plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Load signing key properties from key.properties file
val keystorePropertiesFile = rootProject.file("../local_files/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// Copy the appropriate google-services.json before build
tasks.register<Copy>("copyDebugGoogleServices") {
    from("../../local_files/google-services_debug.json")
    into(".")
    rename { "google-services.json" }
}

tasks.register<Copy>("copyReleaseGoogleServices") {
    from("../../local_files/google-services_release.json")
    into(".")
    rename { "google-services.json" }
}

tasks.whenTaskAdded {
    if (name == "processDebugGoogleServices") {
        dependsOn("copyDebugGoogleServices")
    }
    if (name == "processReleaseGoogleServices") {
        dependsOn("copyReleaseGoogleServices")
    }
}

android {
    namespace = "dk.stormstyrken.twelvestepsapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        // Debug builds sign with the git-ignored local_files/debug.keystore whose
        // SHA-1 is registered in Google Cloud (Google Sign-In / Drive in debug).
        // Falls back to the stock ~/.android/debug.keystore when it is absent.
        val localDebugKeystore = rootProject.file("../local_files/debug.keystore")
        if (localDebugKeystore.exists()) {
            getByName("debug") {
                storeFile = localDebugKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
        create("release") {
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "../../local_files/my-release-key.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
        }
    }

    defaultConfig {
        applicationId = "dk.stormstyrken.twelvestepsapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8: shrink + obfuscate. Produces build/app/outputs/mapping/release/
            // mapping.txt, which scripts/upload-aab-to-play.sh attaches to the
            // bundle so Play can de-obfuscate crash and ANR stack traces.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Ship the native symbol table too, so Play stops flagging the
            // bundle for missing debug symbols.
            ndk { debugSymbolLevel = "SYMBOL_TABLE" }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
