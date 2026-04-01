import 'dart:typed_data';

/// Customization options for the Noon Payment SDK UI.
///
/// Follows the "Rule of Truth" naming convention:
/// - Unified names (e.g. `backgroundColor`) are used for [Both] platforms.
/// - iOS-only properties are prefixed with `ios` (e.g. `iosPaymentOptionFont`).
/// - Android-only properties are prefixed with `android` (e.g. `androidSpecific`).
///
/// All color values should be provided as hex strings (e.g., "#FF5733").
class NoonPaymentStyle {
  /// [Cross-Platform] Raw bytes for the company logo.
  /// Load via `(await rootBundle.load('assets/logo.png')).buffer.asUint8List()`
  final Uint8List? logoBytes;

  /// [Cross-Platform] Background color of the entire payment sheet.
  final String? backgroundColor;

  // --- Payment Option Heading ---

  /// [Cross-Platform] Title text for the payment methods section.
  final String? paymentOptionHeadingText;

  /// [Cross-Platform] Text color for the payment methods heading.
  final String? paymentOptionHeadingForeground;

  /// [iOS Only] Custom font for the payment options heading (optional).
  final String? iosPaymentOptionHeadingFont;

  /// [iOS Only] Font size for the payment options heading (optional).
  final double? iosPaymentOptionHeadingFontSize;

  // --- Payment Options Tabs ---

  /// [Cross-Platform] Label for individual payment method tabs.
  final String? paymentOptionText;

  /// [Cross-Platform] Text color for payment method tabs.
  final String? paymentOptionForeground;

  /// [Cross-Platform] Background color for payment method tabs.
  final String? paymentOptionBackground;

  /// [iOS Only] Border color for payment method tabs.
  final String? iosPaymentOptionBorderColor;

  /// [iOS Only] Custom font for payment method tabs (optional).
  final String? iosPaymentOptionFont;

  /// [iOS Only] Font size for payment method tabs (optional).
  final double? iosPaymentOptionFontSize;

  // --- Payable Amount Section ---

  /// [Cross-Platform] Background color for the amount display area.
  final String? payableAreaBackground;

  /// [Cross-Platform] Label for the payable amount (e.g. "Total").
  final String? payableAmountText;

  /// [Cross-Platform] Text color for the amount display.
  final String? payableAmountForeground;

  /// [iOS Only] Custom font for the amount display (optional).
  final String? iosPayableAmountFont;

  /// [iOS Only] Font size for the amount display (optional).
  final double? iosPayableAmountFontSize;

  // --- Footer Section ---

  /// [Cross-Platform] Footer text at the bottom of the sheet.
  final String? footerText;

  /// [Cross-Platform] Text color for the footer text.
  final String? footerForeground;

  /// [iOS Only] Custom font for the footer text (optional).
  final String? iosFooterFont;

  /// [iOS Only] Font size for the footer text (optional).
  final double? iosFooterFontSize;

  // --- Add New Card ---

  /// [Cross-Platform] Label for the "Add New Card" button.
  final String? addNewCardText;

  /// [Cross-Platform] Text color for the "Add New Card" label.
  final String? addNewCardForeground;

  /// [iOS Only] Custom font for the "Add New Card" label (optional).
  final String? iosAddNewCardFont;

  /// [iOS Only] Font size for the "Add New Card" label (optional).
  final double? iosAddNewCardFontSize;

  // --- Pay Now Button ---

  /// [Cross-Platform] Background color for the "Pay Now" button.
  final String? payNowButtonBackground;

  /// [Cross-Platform] Text color for the "Pay Now" button.
  final String? payNowButtonForeground;

  /// [Cross-Platform] Label for the "Pay Now" button.
  final String? payNowButtonText;

  /// [iOS Only] Custom font for the "Pay Now" button (optional).
  final String? iosPayNowButtonFont;

  /// [iOS Only] Font size for the "Pay Now" button (optional).
  final double? iosPayNowButtonFontSize;

  /// [iOS Only] Corner radius for the "Pay Now" button.
  final double? iosPayNowButtonRadius;

  // --- Yes/No Buttons (iOS Only Styling) ---

  /// [iOS Only] Text color for the "Yes" button.
  final String? iosYesButtonForeground;

  /// [iOS Only] Background color for the "Yes" button.
  final String? iosYesButtonBackground;

  /// [iOS Only] Custom font for the "Yes" button (optional).
  final String? iosYesButtonFont;

  /// [iOS Only] Font size for the "Yes" button (optional).
  final double? iosYesButtonFontSize;

  /// [iOS Only] Corner radius for the "Yes" button.
  final double? iosYesButtonRadius;

  /// [iOS Only] Border color for the "Yes" button.
  final String? iosYesButtonBorderColor;

  /// [iOS Only] Text color for the "No" button.
  final String? iosNoButtonForeground;

  /// [iOS Only] Background color for the "No" button.
  final String? iosNoButtonBackground;

  /// [iOS Only] Custom font for the "No" button (optional).
  final String? iosNoButtonFont;

  /// [iOS Only] Font size for the "No" button (optional).
  final double? iosNoButtonFontSize;

  /// [iOS Only] Corner radius for the "No" button.
  final double? iosNoButtonRadius;

  /// [iOS Only] Border color for the "No" button.
  final String? iosNoButtonBorderColor;

  const NoonPaymentStyle({
    this.logoBytes,
    this.backgroundColor,
    this.paymentOptionHeadingText,
    this.paymentOptionHeadingForeground,
    this.iosPaymentOptionHeadingFont,
    this.iosPaymentOptionHeadingFontSize,
    this.paymentOptionText,
    this.paymentOptionForeground,
    this.paymentOptionBackground,
    this.iosPaymentOptionBorderColor,
    this.iosPaymentOptionFont,
    this.iosPaymentOptionFontSize,
    this.payableAreaBackground,
    this.payableAmountText,
    this.payableAmountForeground,
    this.iosPayableAmountFont,
    this.iosPayableAmountFontSize,
    this.footerText,
    this.footerForeground,
    this.iosFooterFont,
    this.iosFooterFontSize,
    this.addNewCardText,
    this.addNewCardForeground,
    this.iosAddNewCardFont,
    this.iosAddNewCardFontSize,
    this.payNowButtonBackground,
    this.payNowButtonForeground,
    this.payNowButtonText,
    this.iosPayNowButtonFont,
    this.iosPayNowButtonFontSize,
    this.iosPayNowButtonRadius,
    this.iosYesButtonForeground,
    this.iosYesButtonBackground,
    this.iosYesButtonFont,
    this.iosYesButtonFontSize,
    this.iosYesButtonRadius,
    this.iosYesButtonBorderColor,
    this.iosNoButtonForeground,
    this.iosNoButtonBackground,
    this.iosNoButtonFont,
    this.iosNoButtonFontSize,
    this.iosNoButtonRadius,
    this.iosNoButtonBorderColor,
  });

  /// Converts the style to a map for MethodChannel communication.
  Map<String, dynamic> toMap() {
    return {
      'logoBytes': logoBytes,
      'backgroundColor': backgroundColor,
      'paymentOptionHeadingText': paymentOptionHeadingText,
      'paymentOptionHeadingForeground': paymentOptionHeadingForeground,
      'iosPaymentOptionHeadingFont': iosPaymentOptionHeadingFont,
      'iosPaymentOptionHeadingFontSize': iosPaymentOptionHeadingFontSize,
      'paymentOptionText': paymentOptionText,
      'paymentOptionForeground': paymentOptionForeground,
      'paymentOptionBackground': paymentOptionBackground,
      'iosPaymentOptionBorderColor': iosPaymentOptionBorderColor,
      'iosPaymentOptionFont': iosPaymentOptionFont,
      'iosPaymentOptionFontSize': iosPaymentOptionFontSize,
      'payableAreaBackground': payableAreaBackground,
      'payableAmountText': payableAmountText,
      'payableAmountForeground': payableAmountForeground,
      'iosPayableAmountFont': iosPayableAmountFont,
      'iosPayableAmountFontSize': iosPayableAmountFontSize,
      'footerText': footerText,
      'footerForeground': footerForeground,
      'iosFooterFont': iosFooterFont,
      'iosFooterFontSize': iosFooterFontSize,
      'addNewCardText': addNewCardText,
      'addNewCardForeground': addNewCardForeground,
      'iosAddNewCardFont': iosAddNewCardFont,
      'iosAddNewCardFontSize': iosAddNewCardFontSize,
      'payNowButtonBackground': payNowButtonBackground,
      'payNowButtonForeground': payNowButtonForeground,
      'payNowButtonText': payNowButtonText,
      'iosPayNowButtonFont': iosPayNowButtonFont,
      'iosPayNowButtonFontSize': iosPayNowButtonFontSize,
      'iosPayNowButtonRadius': iosPayNowButtonRadius,
      'iosYesButtonForeground': iosYesButtonForeground,
      'iosYesButtonBackground': iosYesButtonBackground,
      'iosYesButtonFont': iosYesButtonFont,
      'iosYesButtonFontSize': iosYesButtonFontSize,
      'iosYesButtonRadius': iosYesButtonRadius,
      'iosYesButtonBorderColor': iosYesButtonBorderColor,
      'iosNoButtonForeground': iosNoButtonForeground,
      'iosNoButtonBackground': iosNoButtonBackground,
      'iosNoButtonFont': iosNoButtonFont,
      'iosNoButtonFontSize': iosNoButtonFontSize,
      'iosNoButtonRadius': iosNoButtonRadius,
      'iosNoButtonBorderColor': iosNoButtonBorderColor,
    }..removeWhere((key, value) => value == null);
  }
}
