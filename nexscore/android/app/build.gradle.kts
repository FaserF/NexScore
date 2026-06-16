plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

android {
    namespace = "de.fabiseitz.nex_score"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }



    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("RELEASE_STORE_FILE") ?: (project.findProperty("RELEASE_STORE_FILE") as String?)
            if (!keystorePath.isNullOrEmpty() && file(keystorePath).exists()) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("RELEASE_STORE_PASSWORD") ?: (project.findProperty("RELEASE_STORE_PASSWORD") as String?)
                keyAlias = System.getenv("RELEASE_KEY_ALIAS") ?: (project.findProperty("RELEASE_KEY_ALIAS") as String?)
                keyPassword = System.getenv("RELEASE_KEY_PASSWORD") ?: (project.findProperty("RELEASE_KEY_PASSWORD") as String?)
            } else {
                val debugConfig = signingConfigs.getByName("debug")
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.fabiseitz.nex_score"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}


// Redundant kotlin { jvmToolchain(17) } removed to avoid conflicts

