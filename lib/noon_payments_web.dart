import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'noon_payments.dart';
import 'noon_payments_platform_interface.dart';

/// A web implementation of the NoonPaymentsPlatform of the NoonPayments plugin.
///
/// Noon Payments SDK is not available on web. This implementation returns
/// a failed result with a clear error message.
class NoonPaymentsWeb extends NoonPaymentsPlatform {
  /// Constructs a NoonPaymentsWeb
  NoonPaymentsWeb();

  static void registerWith(Registrar registrar) {
    NoonPaymentsPlatform.instance = NoonPaymentsWeb();
  }

  @override
  Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) async {
    return NoonPaymentResult.failed(
      errorCode: 'PLATFORM_NOT_SUPPORTED',
      errorMessage:
          'Noon Payments SDK is not available on web. Use the Noon Payments web checkout instead.',
    );
  }
}
