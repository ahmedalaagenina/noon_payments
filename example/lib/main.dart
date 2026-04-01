import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noon_payments/noon_payments.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _paymentResult = "Waiting for action...";
  bool _isLoading = false;

  /// Replace these with real data from your backend.
  ///
  /// 🚧 IMPORTANT: Your server-side INITIATE API must have the correct returnUrl:
  /// Android: https://localhost/noonappsdkresponse
  /// iOS: https://noonpayments.com/sdk/response
  final String testOrderId =
      '123456789012'; // The order Id that is received in the INITIATE API response
  final String testAuthHeader =
      "Key YOUR_AUTHORIZED_KEY"; // The authorization header for your business
  final String testEnvironmentUrl =
      "https://api-test.noonpayments.com/payment/v1/order"; //based on your env.

  /// 🚀 Standard Payment Flow (English)
  Future<void> _startStandardPayment() async {
    setState(() {
      _isLoading = true;
      _paymentResult = 'Launching...';
    });

    try {
      final result = await NoonPayments.initiatePayment(
        orderId: testOrderId,
        authHeader: testAuthHeader,
        environment: NoonEnvironment.sandbox,
        language: NoonPaymentLanguage.english,
      );

      _handleResult(result);
    } catch (e) {
      _handleException(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🎨 Custom Styled Payment Flow with Logo
  Future<void> _startCustomStyledPayment() async {
    setState(() {
      _isLoading = true;
      _paymentResult = 'Launching Styled...';
    });

    try {
      // 1. Optional: Load your company logo from assets if you want it on the payment
      final ByteData rawLogo = await rootBundle.load('assets/icons/icon.png');
      final Uint8List logoBytes = rawLogo.buffer.asUint8List();

      final customStyle = NoonPaymentStyle(
        logoBytes: logoBytes,
        backgroundColor: "#F8F9FA",
        paymentOptionHeadingText: "Secure Checkout",
        paymentOptionHeadingForeground: "#2196F3",
        paynowBackgroundColorHighlight: "#4CAF50",
        payNowForegroundColor: "#FFFFFF",
        payableAmountText: "Amount Due",
        footerText: "Verified by Noon Payments",
        footerForegroundColor: "#9E9E9E",
        // You can add more styles here
      );

      final result = await NoonPayments.initiatePayment(
        orderId: testOrderId,
        authHeader: testAuthHeader,
        environment: NoonEnvironment.sandbox,
        language: NoonPaymentLanguage.english,
        style: customStyle,
      );

      _handleResult(result);
    } catch (e) {
      _handleException(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleResult(NoonPaymentResult result) {
    log("NoonPayment Result: $result");
    setState(() {
      if (result.isSuccess) {
        _paymentResult = '✅ Payment Successful!\nResult: ${result.rawResponse}';
      } else if (result.isCancelled) {
        _paymentResult = '🚫 Payment was cancelled.';
      } else {
        _paymentResult =
            '❌ Payment Failed.\nCode: ${result.errorCode}\nMessage: ${result.errorMessage}';
      }
    });
  }

  void _handleException(dynamic e) {
    log("Plugin Error: $e");
    setState(() {
      _paymentResult = '💀 Unexpected Plugin Error:\n$e';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Noon Payments Example'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.shopping_bag_outlined),
                        title: Text('Order #$testOrderId'),
                        subtitle: Text('Total Amount: 100.00 AED'),
                      ),
                      Divider(height: 1),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Scan the item or proceed to secure payment using Noon Payments SDK below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _paymentResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  onPressed: _startStandardPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text('Standard Payment'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _startCustomStyledPayment,
                  icon: const Icon(Icons.brush),
                  label: const Text('Custom Styled Payment'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
