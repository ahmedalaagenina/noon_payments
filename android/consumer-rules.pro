# ===== Noon Payments SDK =====
-keep class com.noonpayments.** { *; }
-dontwarn com.noonpayments.**

# Coil image loading
-keep class coil.** { *; }
-dontwarn coil.**

# ---- Attributes required for reflection-based (de)serialization ----
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keepattributes Exceptions
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault

# ---- Gson ----
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class sun.misc.Unsafe { *; }
-keep,allowobfuscation class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
# Keep fields of all model classes so Gson can (de)serialize them
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ---- Retrofit ----
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keepclasseswithmembers class * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# ---- OkHttp / Okio ----
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ---- RxJava2 ----
-keep class io.reactivex.** { *; }
-dontwarn io.reactivex.**

# ---- Kotlin metadata (needed for SDK reflection workaround & coroutines) ----
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlinx.**

# ---- Google Pay (play-services-wallet) ----
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.**
