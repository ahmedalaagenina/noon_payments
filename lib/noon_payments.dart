import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

import 'models/noon_apple_pay.dart';
import 'models/noon_payment_enums.dart';
import 'models/noon_payment_result.dart';
import 'models/noon_payment_style.dart';
import 'noon_payments_platform_interface.dart';

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
  // These methods present the *native* Apple Pay sheet (PassKit) instead of
  // Noon's drop-in payment sheet, then submit the resulting token to Noon's
  // INITIATE API. See the README "Apple Pay (Direct Integration)" section.
  // ---------------------------------------------------------------------------

  /// Whether the current device can make Apple Pay payments.
  ///
  /// Returns `false` on non-iOS platforms and when the device/account is not
  /// set up for Apple Pay. Use this to decide whether to show the Apple Pay
  /// button.
  static Future<bool> isApplePayAvailable() {
    return NoonPaymentsPlatform.instance.isApplePayAvailable();
  }

  /// Presents the native Apple Pay sheet and returns the collected token.
  ///
  /// Use this when you want to forward the token to **your own backend**, which
  /// then calls Noon's INITIATE API (the most secure option, keeping your auth
  /// key off the device). Send [NoonApplePayToken.paymentInfo] to your server.
  ///
  /// Returns `null` if the user cancels the sheet. Throws a [PlatformException]
  /// if Apple Pay is unavailable or the request is misconfigured.
  static Future<NoonApplePayToken?> presentApplePay(NoonApplePayConfig config) {
    return NoonPaymentsPlatform.instance.presentApplePay(config);
  }

  /// Presents the native Apple Pay sheet and, on authorization, submits the
  /// token directly to Noon's INITIATE API.
  ///
  /// This is the convenience client-side flow, consistent with
  /// [initiatePayment]: the [authHeader] is used on the device. If you prefer
  /// to keep credentials on your server, use [presentApplePay] and call
  /// [initiateApplePayOrder] (or your own endpoint) from the backend.
  ///
  /// Returns a [NoonPaymentResult] describing the outcome. A cancelled sheet
  /// yields [NoonPaymentResult.cancelled].
  static Future<NoonPaymentResult> payWithApplePay({
    required NoonApplePayConfig config,
    required NoonOrder order,
    required String authHeader,
    required NoonEnvironment environment,
    String paymentAction = 'AUTHORIZE,SALE',
  }) async {
    try {
      final NoonApplePayToken? token = await presentApplePay(config);
      if (token == null) {
        return NoonPaymentResult.cancelled();
      }

      return initiateApplePayOrder(
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

  /// Submits an Apple Pay [token] to Noon's INITIATE API (Noon decrypts the
  /// token on its side — no certificate handling required from you).
  ///
  /// This performs an HTTPS POST from the device using [authHeader]. Prefer
  /// calling INITIATE from your backend when you can keep the key off-device.
  static Future<NoonPaymentResult> initiateApplePayOrder({
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

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(environment.url));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, authHeader);
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NoonPaymentResult.fromInitiateResponse(responseBody);
      }

      // Noon returns a structured error body for most 4xx responses.
      if (responseBody.trim().isNotEmpty) {
        return NoonPaymentResult.fromInitiateResponse(responseBody);
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
    } finally {
      client?.close();
    }
  }
}

