# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# web3dart / Ethereum
-keep class org.web3j.** { *; }
-keep class com.sun.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Suppress missing Play Core classes (Flutter deferred components — not used in this app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Suppress other common missing classes
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
