import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/noon_apple_pay.dart';
import 'models/noon_payment_enums.dart';
import 'models/noon_payment_result.dart';
import 'models/noon_payment_style.dart';
import 'noon_payments_platform_interface.dart';

/// An implementation of [NoonPaymentsPlatform] that uses method channels.
class MethodChannelNoonPayments extends NoonPaymentsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('noon_payments');

  @override
  Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'orderId': orderId,
        'authHeader': authHeader,
        'url': environment.url,
        'language': language.code,
      };

      if (style != null) {
        arguments.addAll(style.toMap());
      }

      final String? result = await methodChannel.invokeMethod(
        'startPayment',
        arguments,
      );

      if (result != null) {
        return NoonPaymentResult.parse(result);
      } else {
        return NoonPaymentResult.cancelled();
      }
    } on PlatformException catch (e) {
      log("Noon Payment error: '${e.code}' - '${e.message}'");

      if (e.code.toLowerCase().contains("cancelled")) {
        return NoonPaymentResult.cancelled();
      }

      return NoonPaymentResult.failed(
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e) {
      log("Noon Payment unexpected error: '$e'");
      return NoonPaymentResult.failed(
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<bool> isApplePayAvailable() async {
    try {
      final bool? available = await methodChannel.invokeMethod<bool>(
        'isApplePayAvailable',
      );
      return available ?? false;
    } on PlatformException catch (e) {
      log("Noon Apple Pay availability error: '${e.code}' - '${e.message}'");
      return false;
    } on MissingPluginException {
      // Method not implemented on this platform (e.g. Android).
      return false;
    }
  }

  @override
  Future<NoonApplePayToken?> getApplePayToken(NoonApplePayConfig config) async {
    final Map<dynamic, dynamic>? result = await methodChannel
        .invokeMethod<Map<dynamic, dynamic>>(
          'getApplePayToken',
          config.toMap(),
        );

    if (result == null) {
      // User cancelled the Apple Pay sheet.
      return null;
    }

    return NoonApplePayToken.fromMap(result);
  }
}
