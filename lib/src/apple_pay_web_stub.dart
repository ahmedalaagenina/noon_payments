import '../models/noon_apple_pay.dart';
import '../models/noon_payment_result.dart';

/// Non-web fallback. These are never reached on native platforms because the
/// public API guards web-only paths with `kIsWeb`.

/// Always `false` off the web.
bool applePayWebAvailable() => false;

/// Not supported off the web.
Future<NoonPaymentResult> runApplePayWebSession({
  required NoonApplePayConfig config,
  required Future<String> Function(String validationUrl) onValidateMerchant,
  required Future<NoonPaymentResult> Function(String paymentInfo)
      onPaymentAuthorized,
}) {
  throw UnsupportedError(
    'Apple Pay on the web is only available in Flutter Web builds.',
  );
}
