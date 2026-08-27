# R8 keep rules. The Flutter Gradle plugin adds its own rules for the engine and
# embedding; these cover plugins that reach classes reflectively.

# flutter_local_notifications serialises scheduled notifications with Gson.
-keep class com.dexterous.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * { @com.google.gson.annotations.SerializedName <fields>; }

# Google Sign-In / Play services ship consumer rules; keep the referenced
# but absent Play Core split-install classes from failing the build.
-dontwarn com.google.android.play.core.**
