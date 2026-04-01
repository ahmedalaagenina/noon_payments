import 'package:flutter_test/flutter_test.dart';
import 'package:noon_payments/noon_payments.dart';
import 'package:noon_payments/noon_payments_method_channel.dart';
import 'package:noon_payments/noon_payments_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNoonPaymentsPlatform
    with MockPlatformInterfaceMixin
    implements NoonPaymentsPlatform {
  @override
  Future<NoonPaymentResult> initiatePayment({
    required String orderId,
    required String authHeader,
    required NoonEnvironment environment,
    NoonPaymentLanguage language = NoonPaymentLanguage.english,
    NoonPaymentStyle? style,
  }) =>
      Future.value(NoonPaymentResult.parse('{"status":"success"}'));
}

void main() {
  final NoonPaymentsPlatform initialPlatform = NoonPaymentsPlatform.instance;

  test('$MethodChannelNoonPayments is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNoonPayments>());
  });

  test('NoonPaymentResult.parse correctly handles valid success JSON', () {
    final result =
        NoonPaymentResult.parse('{"resultCode":0,"message":"Success"}');
    expect(result.isSuccess, true);
    expect(result.isCancelled, false);
    expect(result.isFailed, false);
    expect(result.data, isNotNull);
    expect(result.data!['resultCode'], 0);
  });

  test('NoonPaymentResult.cancelled works correctly', () {
    final result = NoonPaymentResult.cancelled();
    expect(result.isSuccess, false);
    expect(result.isCancelled, true);
    expect(result.isFailed, false);
  });

  test('NoonPaymentResult.failed works correctly', () {
    final result = NoonPaymentResult.failed(
      errorCode: 'TEST_ERROR',
      errorMessage: 'Test error message',
    );
    expect(result.isSuccess, false);
    expect(result.isCancelled, false);
    expect(result.isFailed, true);
    expect(result.errorCode, 'TEST_ERROR');
    expect(result.errorMessage, 'Test error message');
  });

  test('NoonPaymentStyle.toMap excludes null values', () {
    const style = NoonPaymentStyle(
      backgroundColor: '#FFFFFF',
      payNowButtonText: 'Pay',
    );
    final map = style.toMap();
    expect(map.length, 2);
    expect(map['backgroundColor'], '#FFFFFF');
    expect(map['payNowButtonText'], 'Pay');
    expect(map.containsKey('footerText'), false);
  });

  test('NoonPaymentLanguage enum has correct codes', () {
    expect(NoonPaymentLanguage.english.code, 'en');
    expect(NoonPaymentLanguage.arabic.code, 'ar');
  });
}
