import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'models/noon_apple_pay.dart';
import 'models/noon_payment_enums.dart';
import 'models/noon_payment_result.dart';
import 'models/noon_payment_style.dart';
import 'noon_payments_platform_interface.dart';
// Web-only Apple Pay (ApplePaySession JS API). Falls back to a stub that is
// never reached on non-web platforms, guarded by [kIsWeb].
import 'src/apple_pay_web_stub.dart'
    if (dart.library.js_interop) 'src/apple_pay_web.dart'
    as apple_pay_web;

export 'models/noon_apple_pay.dart';
export 'models/noon_payment_enums.dart';
export 'models/noon_payment_result.dart';
export 'models/noon_payment_style.dart';

/// Flutter plugin for Noon Payments SDK.
///
/// Use [initiatePayment] to start a payment flow with the Noon Payments SDK.
///
/// **Important:** When creating an order via the INITIATE API on your backend,
/// you MUST set `returnUrl` to `https://localhost/noonappsdkresponse` (Android)
/// or `https://noonpayments.com/sdk/response` (iOS) for the SDK to work correctly.
///
/// Example usage:
/// ```dart
/// final result = await NoonPayments.initiatePayment(
///   orderId: '123456789012',
///   authHeader: 'Key YOUR_AUTH_KEY',
///   environment: NoonEnvironment.sandbox,
///   language: NoonPaymentLanguage.english,
/// );
///
/// if (result.isSuccess) {
///   print('Payment successful');
/// } else if (result.isCancelled) {
///   print('Payment cancelled');
/// } else {
///   print('Payment failed: ${result.errorMessage}');
/// }
/// ```
class NoonPayments {
  /// Initiates a payment flow using the Noon Payments SDK.
  ///
  /// Parameters:
  /// - [orderId]: The order ID obtained from the INITIATE API response (as a String).
  /// - [authHeader]: The authorization header (e.g., "Key base64EncodedKey").
  /// - [environment]: The environment to use (Sandbox, Production, or Custom).
  /// - [language]: The language for the payment UI (defaults to English).
  /// - [style]: Optional UI customization for the payment screen.
  ///
  /// Returns a [NoonPaymentResult] with the payment outcome.
  static Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) {
    return NoonPaymentsPlatform.instance.initiatePayment(
      orderId: orderId,
      authHeader: authHeader,
      environment: environment,
      language: language,
      style: style,
    );
  }

  // ---------------------------------------------------------------------------
  // Apple Pay — Direct Integration
  //
  // Presents Apple's own Apple Pay UI — PassKit on iOS, `ApplePaySession` in the
  // browser on Web — instead of Noon's drop-in payment sheet, then submits the
  // resulting token to Noon. See the README "Apple Pay (Direct Integration)"
  // section for setup (iOS capability, web SDK script, domain registration).
  // ---------------------------------------------------------------------------

  /// Whether the current device/browser can (likely) make Apple Pay payments.
  ///
  /// - On **iOS**, returns `true` when the device supports Apple Pay.
  /// - On **Android**, always returns `false`.
  /// - On **Flutter Web**, returns `true` in **Safari** (built in) and in
  ///   **Chrome/Edge** *only when Apple's JS SDK script is loaded* in
  ///   `web/index.html` (which also enables the cross-device QR). Without that
  ///   script, non-Safari browsers return `false`.
  ///
  /// Use this to decide whether to show the Apple Pay button.
  ///
  /// Resolves via the active platform implementation (the method channel on
  /// iOS/Android, the web plugin on Flutter Web).
  static Future<bool> isApplePayAvailable() {
    return NoonPaymentsPlatform.instance.isApplePayAvailable();
  }

  /// **iOS only.** Presents the native Apple Pay sheet and returns the
  /// collected token, so **your backend** can call Noon's INITIATE API (the
  /// most secure option, keeping your auth key off the device). Send
  /// [NoonApplePayToken.paymentInfo] to your server.
  ///
  /// Pair with [submitApplePayToken] if you want the package to make the Noon
  /// call instead. Returns `null` if the user cancels the sheet. Throws a
  /// [PlatformException] if Apple Pay is unavailable or misconfigured.
  static Future<NoonApplePayToken?> getApplePayToken(
    NoonApplePayConfig config,
  ) {
    return NoonPaymentsPlatform.instance.getApplePayToken(config);
  }

  /// **iOS only — convenient all-in-one flow.** Presents the native PassKit
  /// sheet and, on authorization, submits the token to Noon's `INITIATE` API in
  /// a single call (the [authHeader] is used on the device).
  ///
  /// On **Flutter Web** this is not usable — the browser cannot call Noon
  /// directly (CORS), so it returns a failed result with code `USE_SERVER_SIDE`.
  /// Use [payWithApplePayServerSide] on web instead.
  ///
  /// To keep your auth key **off the device** on iOS, use [getApplePayToken]
  /// (returns the token) and call Noon from your backend.
  ///
  /// Returns a [NoonPaymentResult]; a cancelled sheet yields
  /// [NoonPaymentResult.cancelled].
  static Future<NoonPaymentResult> payWithApplePay({
    required NoonApplePayConfig config,
    required NoonOrder order,
    required String authHeader,
    required NoonEnvironment environment,
    String paymentAction = 'AUTHORIZE,SALE',
  }) async {
    if (kIsWeb) {
      // On the web the browser cannot call Noon directly (CORS blocks the
      // merchant-validation request). The two Noon calls must run on your
      // server, so use [payWithApplePayServerSide] instead.
      return Future.value(NoonPaymentResult.failed(
        errorCode: 'USE_SERVER_SIDE',
        errorMessage: 'On Flutter Web, use NoonPayments.payWithApplePayServerSide(...) '
            '— calling Noon directly from the browser is blocked by CORS.',
      ));
    }

    try {
      final NoonApplePayToken? token = await getApplePayToken(config);
      if (token == null) {
        return NoonPaymentResult.cancelled();
      }

      return submitApplePayToken(
        order: order,
        authHeader: authHeader,
        environment: environment,
        token: token,
        paymentAction: paymentAction,
      );
    } on PlatformException catch (e) {
      log("Noon Apple Pay error: '${e.code}' - '${e.message}'");
      if (e.code.toLowerCase().contains('cancel')) {
        return NoonPaymentResult.cancelled();
      }
      return NoonPaymentResult.failed(
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e) {
      log("Noon Apple Pay unexpected error: '$e'");
      return NoonPaymentResult.failed(
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  /// Backend-delegated Apple Pay on the **Web** (keeps your Noon key off the
  /// browser and avoids CORS). Presents the `ApplePaySession` and routes the
  /// two Noon calls through callbacks that hit **your backend**:
  ///
  /// - [onValidateMerchant] receives Apple's `validationUrl`. Send it to your
  ///   server, which calls Noon `INITIATE` (with `paymentData.data.validationUrl`)
  ///   and returns the `validationData` string from the response.
  /// - [onPaymentAuthorized] receives the stringified Apple Pay token
  ///   (`paymentInfo`). Send it to your server, which calls Noon
  ///   `PROCESS_AUTHENTICATION` (with the order id it created in the previous
  ///   step) and returns the resulting [NoonPaymentResult].
  ///
  /// Your backend correlates the two calls (e.g. via the user session or the
  /// order reference). This is the recommended web flow for production.
  ///
  /// Set [enableLogs] to `true` to print each step of the flow to the browser
  /// console (prefixed with `🍏 NoonApplePayWeb:`) — useful for debugging a
  /// live deployment. Leave it `false` in production.
  ///
  /// Web only — returns a failed result on other platforms.
  static Future<NoonPaymentResult> payWithApplePayServerSide({
    required NoonApplePayConfig config,
    required Future<String> Function(String validationUrl) onValidateMerchant,
    required Future<NoonPaymentResult> Function(String paymentInfo)
        onPaymentAuthorized,
    bool enableLogs = false,
  }) {
    if (!kIsWeb) {
      return Future.value(NoonPaymentResult.failed(
        errorCode: 'UNSUPPORTED_PLATFORM',
        errorMessage:
            'payWithApplePayServerSide is only available on Flutter Web.',
      ));
    }
    return apple_pay_web.runApplePayWebSession(
      config: config,
      onValidateMerchant: onValidateMerchant,
      onPaymentAuthorized: onPaymentAuthorized,
      enableLogs: enableLogs,
    );
  }

  /// Submits an Apple Pay [token] to Noon's INITIATE API (Noon decrypts the
  /// token on its side — no certificate handling required from you).
  ///
  /// This is the second half of [payWithApplePay] on iOS — pair it with
  /// [getApplePayToken] if you want to do something between collecting the
  /// token and charging. It performs an HTTPS POST using [authHeader]; prefer
  /// calling Noon from your backend when you can keep the key off-device.
  static Future<NoonPaymentResult> submitApplePayToken({
    required NoonOrder order,
    required String authHeader,
    required NoonEnvironment environment,
    required NoonApplePayToken token,
    String paymentAction = 'AUTHORIZE,SALE',
  }) async {
    final Map<String, dynamic> body = {
      'apiOperation': 'INITIATE',
      'order': order.toMap(),
      'configuration': {'paymentAction': paymentAction},
      'paymentData': {
        'type': 'ApplePay',
        'data': {'paymentInfo': token.paymentInfo},
      },
    };

    try {
      final response = await http.post(
        Uri.parse(environment.url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode(body),
      );

      // Noon returns a structured body (with resultCode/message) for both
      // success and most error responses, so parse it whenever present.
      if (response.body.trim().isNotEmpty) {
        return NoonPaymentResult.fromInitiateResponse(response.body);
      }
      return NoonPaymentResult.failed(
        errorCode: 'HTTP_${response.statusCode}',
        errorMessage: 'INITIATE request failed (${response.statusCode}).',
      );
    } catch (e) {
      log("Noon INITIATE request error: '$e'");
      return NoonPaymentResult.failed(
        errorCode: 'NETWORK_ERROR',
        errorMessage: e.toString(),
      );
    }
  }
}

