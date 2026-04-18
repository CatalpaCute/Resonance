import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingValue(key: String, envKey: String): String? =
    keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() }
        ?: System.getenv(envKey)?.takeIf { it.isNotBlank() }

android {
    namespace = "com.example.rsstool"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.rsstool"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Prefer CI-generated key.properties and fall back to environment variables
            // so release signing works in automation without blocking local development.
            val storeFilePath = signingValue("storeFile", "KEYSTORE_PATH")
            val storePasswordValue = signingValue("storePassword", "KEYSTORE_PASSWORD")
            val keyAliasValue = signingValue("keyAlias", "KEY_ALIAS")
            val keyPasswordValue = signingValue("keyPassword", "KEY_PASSWORD")

            if (!storeFilePath.isNullOrBlank() &&
                !storePasswordValue.isNullOrBlank() &&
                !keyAliasValue.isNullOrBlank() &&
                !keyPasswordValue.isNullOrBlank()
            ) {
                storeFile = rootProject.file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            val hasReleaseSigning = releaseSigning.storeFile != null &&
                !releaseSigning.storePassword.isNullOrBlank() &&
                !releaseSigning.keyAlias.isNullOrBlank() &&
                !releaseSigning.keyPassword.isNullOrBlank()

            // Keep a debug-signing fallback for local release builds when CI secrets are absent.
            signingConfig = if (hasReleaseSigning) releaseSigning else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
