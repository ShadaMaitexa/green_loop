# TensorFlow Lite ProGuard rules
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.** { *; }

# Prevent R8 from warning about missing classes in these packages
-dontwarn org.tensorflow.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
