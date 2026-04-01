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

/// Enum representing the Noon Payments environment.
enum NoonEnvironment {
  /// Sandbox environment (Testing)
  sandbox("https://api-test.noonpayments.com/payment/v1/order"),

  /// Production environment (Live)
  production("https://api.noonpayments.com/payment/v1/order");

  /// The Noon API base URL for this environment.
  final String url;

  const NoonEnvironment(this.url);
}
