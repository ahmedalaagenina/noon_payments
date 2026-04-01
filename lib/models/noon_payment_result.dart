import 'dart:convert';
import 'noon_payment_enums.dart';

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
