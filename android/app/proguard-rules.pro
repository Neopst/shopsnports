# Add project-specific ProGuard rules here.
# Keep model classes and any reflection usages as needed.
# See: https://developer.android.com/studio/build/shrink-code

# Keep native method mappings
-keepclassmembers class * {
    native <methods>;
}

# If using Firebase or other libraries that rely on reflection, add rules as needed.
# Example for Gson (if used):
#-keep class com.yourpackage.** { *; }

# Keep Flutter Plugin registrant
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Crashlytics mapping (if using)
-keepattributes *Annotation*

# Keep Play Core / splitinstall classes used by Flutter deferred components
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep any generated Flutter Play Store split application classes
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
