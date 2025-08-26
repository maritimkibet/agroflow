# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Aggressive optimization for smaller APK
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove debug information
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Keep Firebase classes (minimal)
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.database.** { *; }
-keep class com.google.firebase.storage.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep Flutter classes (essential only)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep Hive classes (minimal)
-keep class hive.** { *; }
-keep class **.g.dart { *; }

# Keep notification classes (essential)
-keep class me.carda.awesome_notifications.core.** { *; }

# Obfuscate sensitive classes while keeping functionality
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Remove unused resources and suppress warnings
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Fix Play Store split install issues
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Fix Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**