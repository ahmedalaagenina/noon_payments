import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'models/noon_apple_pay.dart';
import 'models/noon_payment_enums.dart';
import 'models/noon_payment_result.dart';
import 'models/noon_payment_style.dart';
import 'noon_payments_platform_interface.dart';
import 'src/apple_pay_web.dart' as apple_pay_web;

/// The Flutter Web implementation of the `noon_payments` plugin.
///
/// Registered automatically on web (declared under `flutter.plugin.platforms.web`
/// in `pubspec.yaml`). On the web **only Apple Pay** is supported — via
/// `NoonPayments.payWithApplePayServerSide(...)`. The native drop-in payment
/// sheet and Google Pay are mobile-only.
class NoonPaymentsWeb extends NoonPaymentsPlatform {
  /// Registers [NoonPaymentsWeb] as the default [NoonPaymentsPlatform] on web.
  static void registerWith(Registrar registrar) {
    NoonPaymentsPlatform.instance = NoonPaymentsWeb();
  }

  @override
  Future<bool> isApplePayAvailable() async {
    return apple_pay_web.applePayWebAvailable();
  }

  @override
  Future<NoonApplePayToken?> getApplePayToken(NoonApplePayConfig config) {
    throw UnsupportedError(
      'getApplePayToken is iOS-only. On Flutter Web use '
      'NoonPayments.payWithApplePayServerSide(...).',
    );
  }

  @override
  Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) {
    return Future.value(NoonPaymentResult.failed(
      errorCode: 'UNSUPPORTED_PLATFORM',
      errorMessage: 'The Noon drop-in payment sheet is not available on Flutter '
          'Web. Web supports Apple Pay only (payWithApplePayServerSide).',
    ));
  }
}
