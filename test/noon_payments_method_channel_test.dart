import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noon_payments/noon_payments.dart';
import 'package:noon_payments/noon_payments_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNoonPayments platform = MethodChannelNoonPayments();
  const MethodChannel channel = MethodChannel('noon_payments');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'startPayment') {
        return '{"resultCode":0,"message":"Success"}';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initiatePayment returns success result', () async {
    final result = await platform.initiatePayment(
      orderId: '123456789',
      authHeader: 'Key test',
      environment: NoonEnvironment.sandbox,
    );
    expect(result.isSuccess, true);
    expect(result.rawResponse, '{"resultCode":0,"message":"Success"}');
  });

  test('initiatePayment returns cancelled on null result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    final result = await platform.initiatePayment(
      orderId: '123456789',
      authHeader: 'Key test',
      environment: NoonEnvironment.sandbox,
    );
    expect(result.isCancelled, true);
  });
}
