import 'models/noon_payment_enums.dart';
import 'models/noon_payment_result.dart';
import 'models/noon_payment_style.dart';
import 'noon_payments_platform_interface.dart';

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
}

