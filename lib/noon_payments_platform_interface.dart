import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'noon_payments.dart';
import 'noon_payments_method_channel.dart';

/// The interface that implementations of noon_payments must implement.
///
/// Platform implementations should extend this class rather than
/// implement it as `NoonPaymentsPlatform`.
abstract class NoonPaymentsPlatform extends PlatformInterface {
  /// Constructs a NoonPaymentsPlatform.
  NoonPaymentsPlatform() : super(token: _token);

  static final Object _token = Object();

  static NoonPaymentsPlatform _instance = MethodChannelNoonPayments();

  /// The default instance of [NoonPaymentsPlatform] to use.
  ///
  /// Defaults to [MethodChannelNoonPayments].
  static NoonPaymentsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NoonPaymentsPlatform] when
  /// they register themselves.
  static set instance(NoonPaymentsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initiates a payment with the Noon Payments SDK.
  Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) {
    throw UnimplementedError('initiatePayment() has not been implemented.');
  }
}
