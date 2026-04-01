import 'dart:convert';
import 'dart:typed_data';

import 'noon_payments_platform_interface.dart';

/// Represents the language to use in the Noon Payment SDK UI.
enum NoonPaymentLanguage {
  /// English language
  english('en'),

  /// Arabic language
  arabic('ar');

  final String code;
  const NoonPaymentLanguage(this.code);
}

/// Enum representing possible payment result statuses.
enum NoonPaymentStatus {
  /// Payment completed successfully
  success,

  /// Payment was cancelled by the user
  cancelled,

  /// Payment failed due to an error
  failed,
}

/// Enum representing the Noon Payments environment.
enum NoonEnvironment {
  /// Sandbox environment (Testing)
  sandbox("https://api-test.noonpayments.com/payment/v1/order"),

  /// Production environment (Live)
  production("https://api.noonpayments.com/payment/v1/order");

  /// The Noon API base URL for this environment.
  final String url;

  const NoonEnvironment(this.url);
}

/// A structured result from the Noon Payment SDK.
class NoonPaymentResult {
  /// The status of the payment
  final NoonPaymentStatus status;

  /// The raw JSON response string from the SDK (available on success)
  final String? rawResponse;

  /// Parsed response data (available on success)
  final Map<String, dynamic>? data;

  /// Error message if payment failed
  final String? errorMessage;

  /// Error code if payment failed
  final String? errorCode;

  const NoonPaymentResult._({
    required this.status,
    this.rawResponse,
    this.data,
    this.errorMessage,
    this.errorCode,
  });

  /// Parses a result from the raw SDK response.
  /// Intelligently checks if the response is actually an error payload.
  factory NoonPaymentResult.parse(String rawResponse) {
    if (rawResponse.trim().isEmpty || rawResponse == 'null') {
      return NoonPaymentResult.failed(
        errorCode: 'EMPTY_RESPONSE',
        errorMessage: 'The SDK returned an empty or invalid response. Usually indicates an invalid OrderID or a cancelled initialization.',
      );
    }

    Map<String, dynamic>? parsed;
    try {
      parsed = json.decode(rawResponse) as Map<String, dynamic>;
      
      // Look for common error signatures Noon might return
      if (parsed.containsKey('orderStatus')) {
        final orderStatus = parsed['orderStatus'].toString().toUpperCase();
        if (orderStatus != 'SUCCESS' && orderStatus != 'AUTHORIZED' && orderStatus != 'CAPTURED') {
          return NoonPaymentResult.failed(
            errorCode: 'ORDER_STATUS_ERROR',
            errorMessage: 'Payment failed with status: $orderStatus',
          );
        }
      }

      if (parsed.containsKey('resultCode') && parsed['resultCode'] != 0 && parsed['resultCode'] != '0') {
         return NoonPaymentResult.failed(
            errorCode: parsed['resultCode'].toString(),
            errorMessage: parsed['message']?.toString() ?? 'Payment failed',
         );
      }
      if (parsed.containsKey('status') && parsed['status'].toString().toUpperCase() != 'SUCCESS') {
         return NoonPaymentResult.failed(
           errorCode: 'STATUS_ERROR',
           errorMessage: parsed['message']?.toString() ?? 'Payment failed: ${parsed["status"]}',
         );
      }
      if (parsed.containsKey('errorMessage') || parsed.containsKey('error')) {
         return NoonPaymentResult.failed(
           errorCode: parsed['errorCode']?.toString(),
           errorMessage: parsed['errorMessage']?.toString() ?? parsed['error']?.toString() ?? 'Payment failed',
         );
      }
    } catch (_) {
      // Response might not be valid JSON, but it's not empty. Fall back to success.
    }
    
    return NoonPaymentResult._(
      status: NoonPaymentStatus.success,
      rawResponse: rawResponse,
      data: parsed,
    );
  }

  /// Creates a cancelled result
  factory NoonPaymentResult.cancelled() {
    return const NoonPaymentResult._(
      status: NoonPaymentStatus.cancelled,
    );
  }

  /// Creates a failed result
  factory NoonPaymentResult.failed({String? errorCode, String? errorMessage}) {
    return NoonPaymentResult._(
      status: NoonPaymentStatus.failed,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  /// Whether the payment was successful
  bool get isSuccess => status == NoonPaymentStatus.success;

  /// Whether the payment was cancelled
  bool get isCancelled => status == NoonPaymentStatus.cancelled;

  /// Whether the payment failed
  bool get isFailed => status == NoonPaymentStatus.failed;

  @override
  String toString() {
    switch (status) {
      case NoonPaymentStatus.success:
        return 'NoonPaymentResult.success(data: $rawResponse)';
      case NoonPaymentStatus.cancelled:
        return 'NoonPaymentResult.cancelled()';
      case NoonPaymentStatus.failed:
        return 'NoonPaymentResult.failed(code: $errorCode, message: $errorMessage)';
    }
  }
}

/// Customization options for the Noon Payment SDK UI.
///
/// All color values should be provided as hex strings (e.g., "#FF5733").
class NoonPaymentStyle {
  /// Raw bytes for the logo image.
  /// Load this via `(await rootBundle.load('assets/logo.png')).buffer.asUint8List()`
  final Uint8List? logoBytes;

  /// Background color of the payment screen
  final String? backgroundColor;

  /// Heading text for payment options section
  final String? paymentOptionHeadingText;

  /// Foreground color for the payment option heading
  final String? paymentOptionHeadingForeground;

  /// Foreground color for payment options
  final String? paymentOptionForeground;

  /// Background color for payment options
  final String? paymentOptionBackground;

  /// Background color for the payable amount section
  final String? payableBackgroundColor;

  /// Text label for the payable amount
  final String? payableAmountText;

  /// Foreground color for the payable amount
  final String? payableForegroundColor;

  /// Footer text displayed at the bottom
  final String? footerText;

  /// Foreground color for the footer text
  final String? footerForegroundColor;

  /// Text for the "Add new card" button
  final String? addNewCardText;

  /// Foreground color for the "Add new card" text
  final String? addNewCardTextForegroundColor;

  /// Highlight/background color for the "Pay Now" button
  final String? paynowBackgroundColorHighlight;

  /// Foreground color for the "Pay Now" button text
  final String? payNowForegroundColor;

  /// Text for the "Pay Now" button
  final String? paynowText;

  const NoonPaymentStyle({
    this.logoBytes,
    this.backgroundColor,
    this.paymentOptionHeadingText,
    this.paymentOptionHeadingForeground,
    this.paymentOptionForeground,
    this.paymentOptionBackground,
    this.payableBackgroundColor,
    this.payableAmountText,
    this.payableForegroundColor,
    this.footerText,
    this.footerForegroundColor,
    this.addNewCardText,
    this.addNewCardTextForegroundColor,
    this.paynowBackgroundColorHighlight,
    this.payNowForegroundColor,
    this.paynowText,
  });

  /// Converts the style to a map for MethodChannel communication.
  Map<String, dynamic> toMap() {
    return {
      'logoBytes': logoBytes,
      'backgroundColor': backgroundColor,
      'paymentOptionHeadingText': paymentOptionHeadingText,
      'paymentOptionHeadingForeground': paymentOptionHeadingForeground,
      'paymentOptionForeground': paymentOptionForeground,
      'paymentOptionBackground': paymentOptionBackground,
      'payableBackgroundColor': payableBackgroundColor,
      'payableAmountText': payableAmountText,
      'payableForegroundColor': payableForegroundColor,
      'footerText': footerText,
      'footerForegroundColor': footerForegroundColor,
      'addNewCardText': addNewCardText,
      'addNewCardTextForegroundColor': addNewCardTextForegroundColor,
      'paynowBackgroundColorHighlight': paynowBackgroundColorHighlight,
      'payNowForegroundColor': payNowForegroundColor,
      'paynowText': paynowText,
    }..removeWhere((key, value) => value == null);
  }
}

/// Flutter plugin for Noon Payments SDK.
///
/// Use [initiatePayment] to start a payment flow with the Noon Payments SDK.
///
/// **Important:** When creating an order via the INITIATE API on your backend,
/// you MUST set `returnUrl` to `https://localhost/noonappsdkresponse` for the
/// SDK to work correctly.
///
/// Example usage:
/// ```dart
/// final result = await NoonPayments.initiatePayment(
///   orderId: '123456789012',
///   authHeader: 'Key YOUR_AUTH_KEY',
///   environment: NoonEnvironment.test,
///   language: NoonPaymentLanguage.english,
/// );
///
/// if (result.isSuccess) {
///   print('Payment successful: ${result.data}');
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
  /// - [environment]: The environment to use (Test or Live).
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
}

