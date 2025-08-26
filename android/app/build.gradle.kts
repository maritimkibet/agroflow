plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Google Services Plugin
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter Plugin last
}

android {
    namespace = "com.example.agroflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.agroflow"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
            
            // Additional optimizations for smaller APK
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }

    // Split APKs by ABI for smaller downloads
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = false
        }
    }

    // Custom APK naming
    applicationVariants.all {
        outputs.all {
            val outputImpl = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            val abi = outputImpl.getFilter(com.android.build.OutputFile.ABI)
            outputImpl.outputFileName = if (abi != null) {
                "AgroFlow-${abi}.apk"
            } else {
                "AgroFlow.apk"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.firebase:firebase-analytics:21.6.1") // ✅ Firebase Analytics (example)
    // You can add other Firebase libraries here (Firestore, Auth, etc.)
}

flutter {
    source = "../.."
}
