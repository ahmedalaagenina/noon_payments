package com.genina.noon_payments

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import androidx.annotation.NonNull
import com.noonpayments.paymentsdk.models.NoonPaymentsSetup
import com.noonpayments.paymentsdk.models.NoonPaymentsUI
import com.noonpayments.paymentsdk.models.Language
import com.noonpayments.paymentsdk.activities.PaymentMethodSheet
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class NoonPaymentsPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val PAYMENT_REQUEST_CODE = 1001

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "noon_payments")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "startPayment") {
            val orderId = call.argument<String>("orderId")
            val authHeader = call.argument<String>("authHeader")
            val url = call.argument<String>("url")
            val languageStr = call.argument<String>("language") ?: "en"

            if (orderId == null || authHeader == null || url == null) {
                result.error("INVALID_ARGUMENTS", "Missing required arguments (orderId, authHeader, url)", null)
                return
            }

            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity is null", null)
                return
            }

            this.pendingResult = result

            try {
                val noonPaymentsUI = NoonPaymentsUI()

                if (languageStr.lowercase() == "ar") {
                    noonPaymentsUI.setLanguage(Language.ARABIC)
                } else {
                    noonPaymentsUI.setLanguage(Language.ENGLISH)
                }

                call.argument<String>("backgroundColor")?.run { noonPaymentsUI.setBackgroundColor(Color.parseColor(this)) }
                call.argument<String>("paymentOptionHeadingText")?.run { noonPaymentsUI.setPaymentOptionHeadingText(this) }
                call.argument<String>("paymentOptionHeadingForeground")?.run { noonPaymentsUI.setPaymentOptionHeadingForeground(Color.parseColor(this)) }
                call.argument<String>("paymentOptionForeground")?.run { noonPaymentsUI.setPaymentOptionForeground(Color.parseColor(this)) }
                call.argument<String>("paymentOptionBackground")?.run { noonPaymentsUI.setPaymentOptionBackground(Color.parseColor(this)) }
                call.argument<String>("payableAreaBackground")?.run { noonPaymentsUI.setPayableBackgroundColor(Color.parseColor(this)) }
                call.argument<String>("payableAmountText")?.run { noonPaymentsUI.setPayableAmountText(this) }
                call.argument<String>("payableAmountForeground")?.run { noonPaymentsUI.setPayableForegroundColor(Color.parseColor(this)) }
                call.argument<String>("footerText")?.run { noonPaymentsUI.setFooterText(this) }
                call.argument<String>("footerForeground")?.run { noonPaymentsUI.setFooterForegroundColor(Color.parseColor(this)) }
                call.argument<String>("addNewCardText")?.run { noonPaymentsUI.setAddNewCardText(this) }
                call.argument<String>("addNewCardForeground")?.run { noonPaymentsUI.setAddNewCardTextForegroundColor(Color.parseColor(this)) }
                call.argument<String>("payNowButtonBackground")?.run { noonPaymentsUI.setPaynowBackgroundColorHighlight(Color.parseColor(this)) }
                call.argument<String>("payNowButtonForeground")?.run { noonPaymentsUI.setPayNowForegroundColor(Color.parseColor(this)) }
                call.argument<String>("payNowButtonText")?.run { noonPaymentsUI.setPaynowText(this) }

                call.argument<ByteArray>("logoBytes")?.let { bytes ->
                    try {
                        val bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        val drawable = android.graphics.drawable.BitmapDrawable(activity!!.resources, bitmap)
                        noonPaymentsUI.setLogoImage(drawable)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                val noonPaymentsSetup = NoonPaymentsSetup.getInstance()
                noonPaymentsSetup.SetupDataUI(noonPaymentsUI)
                noonPaymentsSetup.Setup(orderId, authHeader, url)

                // WORKAROUND for Noon SDK internal bug: 
                // The SDK crashes with "UninitializedPropertyAccessException: lateinit property data"
                // if the OrderID is invalid because orderIdCancel() reads 'data' without initializing it.
                // We preemptively initialize it here using Reflection to bypass Kotlin's internal module boundary checks!
                try {
                    val baseActivityKtClass = Class.forName("com.noonpayments.paymentsdk.activities.BaseActivityKt")
                    val sdkDataClass = Class.forName("com.noonpayments.paymentsdk.models.NoonPaymentsData")
                    val setDataMethod = baseActivityKtClass.getMethod("setData", sdkDataClass)
                    
                    val dummyData = sdkDataClass.newInstance()
                    
                    // The SDK crashed with NPE because orderIdCancel() calls .toString() on a null field!
                    // Aggressively populate all String fields in the dummy object with empty strings or parameters to prevent NPE.
                    for (method in sdkDataClass.methods) {
                        if (method.name.startsWith("set") && method.parameterTypes.size == 1 && method.parameterTypes[0] == String::class.java) {
                            try { method.invoke(dummyData, "") } catch (e: Exception) {}
                        }
                    }
                    
                    // Pass the real parameters just in case
                    try { sdkDataClass.getMethod("setOrderId", String::class.java).invoke(dummyData, orderId ?: "") } catch(e: Exception) {}
                    try { sdkDataClass.getMethod("setUrl", String::class.java).invoke(dummyData, url ?: "") } catch(e: Exception) {}
                    try { sdkDataClass.getMethod("setAuthorizationHeader", String::class.java).invoke(dummyData, authHeader ?: "") } catch(e: Exception) {}
                    
                    // Inject the safe dummy object into the internal static field
                    setDataMethod.invoke(null, dummyData)
                } catch (ex: Exception) {
                    android.util.Log.e("NoonPaymentsPlugin", "Failed to apply SDK crash workaround", ex)
                }

                val intent = Intent(activity, PaymentMethodSheet::class.java)
                activity!!.startActivityForResult(intent, PAYMENT_REQUEST_CODE)

            } catch (e: Exception) {
                pendingResult?.error("INIT_ERROR", e.message, null)
                pendingResult = null
            }

        } else {
            result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == PAYMENT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val response = data.getStringExtra("noonresponse")
                pendingResult?.success(response)
            } else {
                pendingResult?.error("PAYMENT_CANCELLED", "Payment was cancelled or failed", null)
            }
            pendingResult = null
            return true
        }
        return false
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }
    override fun onDetachedFromActivity() { activity = null }
}
