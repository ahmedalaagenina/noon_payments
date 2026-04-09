/// Represents the language to use in the Noon Payment SDK UI.
enum NoonPaymentLanguage {
  /// English language
  english('en'),

  /// Arabic language
  arabic('ar');

  final String code;
  const NoonPaymentLanguage(this.code);
}

/// Enum representing possible payment result statuses.
enum NoonPaymentStatus {
  /// Payment completed successfully
  success,

  /// Payment was cancelled by the user
  cancelled,

  /// Payment failed due to an error
  failed,
}

/// Class representing the Noon Payments environment and its endpoint URL.
///
/// You can use the predefined constants:
/// - [NoonEnvironment.sandbox]
/// - [NoonEnvironment.production]
///
/// Or instantiate it directly with a custom regional URL:
/// ```dart
/// NoonEnvironment("https://api-test.sa.noonpayments.com/payment/v1/order")
/// ```
class NoonEnvironment {
  /// The absolute URL for this environment's API endpoint.
  final String url;

  const NoonEnvironment(this.url);

  /// Default Sandbox environment (Global)
  static const NoonEnvironment sandbox =
      NoonEnvironment("https://api-test.noonpayments.com/payment/v1/order");

  /// Default Production environment (Global)
  static const NoonEnvironment production =
      NoonEnvironment("https://api.noonpayments.com/payment/v1/order");
}
