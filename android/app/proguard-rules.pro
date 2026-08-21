# ProGuard rules for LocalMind and llama_cpp_dart / JNI / FFI

# Keep all JNI and C++ bridge classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep FFI Structs and bindings
-keep class * extends com.sun.jna.** { *; }
-keep class com.sun.jna.** { *; }

# Keep Flutter plugins and llama_cpp_dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Don't obfuscate model classes used in reflection / serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-dontwarn com.sun.jna.**
-dontwarn com.google.android.play.core.**
