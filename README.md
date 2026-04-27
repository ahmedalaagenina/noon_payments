# Noon Payments Flutter Plugin

[![pub package](https://img.shields.io/pub/v/noon_payments.svg)](https://pub.dev/packages/noon_payments)
[![license](https://img.shields.io/github/license/ahmedalaagenina/noon_payments.svg)](https://github.com/ahmedalaagenina/noon_payments)

A high-performance, professional Flutter plugin for integrating the **Noon Payments SDK (v2.1.0)** on Android and iOS. This plugin provides a seamless way to accept payments in your Flutter app using Noon's secure native payment sheets, with full support for customization and easy environment switching.

---

## ✨ Features

- 📱 **Native Payment Sheet**: Uses officially supported Noon Payments native UI (Android AAR & iOS XCFramework).
- 🎨 **Deep Customization**: Customize UI elements (colors, labels, and logos).
- 🛡️ **Zero-Configuration Bundling**: Native SDKs are **built-in**—no manual downloads required.
- 🧩 **Universal Result Model**: Unified response parsing for success, cancellations, and failures.
- 🍏 **Apple Pay Support**: Seamless integration with Apple Pay via Noon SDK.
- 🤖 **Google Pay Support**: Seamless integration with Google Pay via Noon SDK.
- 🌍 **Localization**: Native support for English and Arabic.
- 🧪 **Modern API**: Clean, type-safe API using `NoonEnvironment` constants and custom endpoints.

---

## 📖 Documentation & SDK Version

- **SDK Version**: 2.1.0 (Android & iOS)
- **Official Documentation**: [docs.noonpayments.com](https://docs.noonpayments.com/)

---

## 🚀 Installation

### 1. Add Dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  noon_payments: ^1.0.1
```

> [!TIP]
> **No manual SDK download is required.** The plugin comes pre-bundled with the Noon Payments native libraries (`.aar` for Android and `.xcframework` for iOS).

---

## 🛠️ Platform Setup

### 🤖 Android Setup

1. **Minimum SDK Version**: Ensure your **app-level** Gradle file has a minimum SDK of at least **26**:
   ```kotlin
   android {
       defaultConfig {
           minSdk = 26
       }
   }
   ```
2. **Enable Data Binding**: Since the Noon SDK uses Data Binding, you must enable it in your **app-level** Gradle file:
   ```kotlin
   android {
       buildFeatures {
           dataBinding = true
       }
   }
   ```
3. **Google Pay Metadata**: Add the following inside your `<application>` tag in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.wallet.api.enabled"
       android:value="true" />
   ```

### 🍎 iOS Setup & Apple Pay

1. **Deployment Target**: Ensure your iOS deployment target is at least **13.0**.
2. **Framework Embedding**: The plugin declares the bundled `NoonPaymentsSDK.xcframework` as a vendored framework in its podspec. If you integrate or inspect it manually in Xcode, ensure it is embedded and signed by the Runner target.
3. **Apple Pay Capabilities**: To enable Apple Pay, you must configure your Apple Developer account and Xcode:
   - Go to your [Apple Developer Portal](https://developer.apple.com/).
   - Create a new **Merchant ID** (e.g., `merchant.com.yourcompany.app`).
   - Open your project in **Xcode**.
   - Go to your target's **Signing & Capabilities** tab.
   - Click `+ Capability` and add **Apple Pay**.
   - Check the box next to the Merchant ID you created.
4. **Noon Dashboard & Certificate Configuration**:
   - **Step 1**: Download the **CSR (Certificate Signing Request)** file from your Noon Payments Dashboard (You May Need to Contact Noon Support for activation).
   - **Step 2**: Upload this CSR to the Apple Developer Portal under your Merchant ID to generate a **Payment Processing Certificate**.
   - **Step 3**: Download the certificate (`.cer`) from Apple and re-upload it back to the Noon Dashboard.
   - **Step 4**: Ensure your Backend sends **YOUR** valid `merchantIdentifier` in your server-side call.
   - **Step 5**: Ensure Mobile SDK is activated in your Noon Payments Dashboard (You can contact Noon Support for activation).

> [!NOTE]
> These Apple Pay steps are for reference only. Contact Noon Support for activation details and dashboard-specific configuration.

---

## 💳 Usage

### ⚙️ 1. Generate Order ID (Server-Side)

Before launching the payment sheet, your backend **must** call Noon's `INITIATE` API.

> [!IMPORTANT]
> You **MUST** set the `returnUrl` correctly in your server-side call for the SDK to return the user to your app:
>
> - **Android**: `https://localhost/noonappsdkresponse`
> - **iOS**: `https://noonpayments.com/sdk/response`

### 🔌 2. Initiate Payment

```dart
import 'package:noon_payments/noon_payments.dart';

final result = await NoonPayments.initiatePayment(
  orderId: "YOUR_ORDER_ID_FROM_BACKEND",
  authHeader: "Key YOUR_AUTHORIZED_KEY_HERE",

  // Use predefined global endpoints:
  environment: NoonEnvironment.sandbox, // or NoonEnvironment.production

  // OR use a custom regional endpoint (e.g., Saudi Arabia):
  // environment: NoonEnvironment(
  //   "https://api-test.sa.noonpayments.com/payment/v1/order",
  // ),

  language: NoonPaymentLanguage.english, // or NoonPaymentLanguage.arabic
);

if (result.isSuccess) {
  print("✅ Payment Successful! Data: ${result.data}");
} else if (result.isCancelled) {
  print("🚫 User cancelled the payment.");
} else {
  print("❌ Payment Failed: ${result.errorMessage} (Code: ${result.errorCode})");
}
```

### 🎨 3. UI Customization (Optional)

```dart
import 'dart:typed_data';

import 'package:flutter/services.dart';

// Load your logo from assets
final ByteData rawLogo = await rootBundle.load('assets/logo.png');
final Uint8List logoBytes = rawLogo.buffer.asUint8List();

final customStyle = NoonPaymentStyle(
  logoBytes: logoBytes,
  backgroundColor: "#F8F9FA",
  paymentOptionHeadingText: "Secure Checkout",
  payNowButtonBackground: "#4CAF50",
  payableAmountText: "Total to Pay",
);

await NoonPayments.initiatePayment(
  // ... other parameters
  style: customStyle,
);
```

---

## 📖 Style Properties

All color values should be hex strings such as `#FFFFFF` or `#4CAF50`.

| Property | Platform | Type | Description |
| :--- | :---: | :---: | :--- |
| `logoBytes` | Both | `Uint8List` | Company logo image bytes. |
| `backgroundColor` | Both | `String` | Background color of the sheet. |
| `paymentOptionHeadingText` | Both | `String` | Title text for the payment methods section. |
| `paymentOptionHeadingForeground` | Both | `String` | Text color for the payment methods heading. |
| `iosPaymentOptionHeadingFont` | iOS | `String` | Custom font name for the payment methods heading. |
| `iosPaymentOptionHeadingFontSize` | iOS | `double` | Font size for the payment methods heading. |
| `paymentOptionText` | Both | `String` | Label for payment method tabs. |
| `paymentOptionForeground` | Both | `String` | Text color for payment method tabs. |
| `paymentOptionBackground` | Both | `String` | Background color for payment method tabs. |
| `iosPaymentOptionBorderColor` | iOS | `String` | Border color for payment method tabs. |
| `iosPaymentOptionFont` | iOS | `String` | Custom font name for payment method tabs. |
| `iosPaymentOptionFontSize` | iOS | `double` | Font size for payment method tabs. |
| `payableAreaBackground` | Both | `String` | Background color for the amount area. |
| `payableAmountText` | Both | `String` | Label for the payable amount. |
| `payableAmountForeground` | Both | `String` | Text color for the amount display. |
| `iosPayableAmountFont` | iOS | `String` | Custom font name for the amount display. |
| `iosPayableAmountFontSize` | iOS | `double` | Font size for the amount display. |
| `footerText` | Both | `String` | Footer text at the bottom. |
| `footerForeground` | Both | `String` | Text color for the footer text. |
| `iosFooterFont` | iOS | `String` | Custom font name for the footer text. |
| `iosFooterFontSize` | iOS | `double` | Font size for the footer text. |
| `addNewCardText` | Both | `String` | Label for the "Add New Card" button. |
| `addNewCardForeground` | Both | `String` | Text color for the "Add New Card" label. |
| `iosAddNewCardFont` | iOS | `String` | Custom font name for the "Add New Card" label. |
| `iosAddNewCardFontSize` | iOS | `double` | Font size for the "Add New Card" label. |
| `payNowButtonBackground` | Both | `String` | Background color for the "Pay Now" button. |
| `payNowButtonForeground` | Both | `String` | Text color for the "Pay Now" button. |
| `payNowButtonText` | Both | `String` | Label for the "Pay Now" button. |
| `iosPayNowButtonFont` | iOS | `String` | Custom font name for the "Pay Now" button. |
| `iosPayNowButtonFontSize` | iOS | `double` | Font size for the "Pay Now" button. |
| `iosPayNowButtonRadius` | iOS | `double` | Corner radius for the "Pay Now" button. |
| `iosYesButtonForeground` | iOS | `String` | Text color for "Yes" confirmation buttons. |
| `iosYesButtonBackground` | iOS | `String` | Background color for "Yes" confirmation buttons. |
| `iosYesButtonFont` | iOS | `String` | Custom font name for "Yes" confirmation buttons. |
| `iosYesButtonFontSize` | iOS | `double` | Font size for "Yes" confirmation buttons. |
| `iosYesButtonRadius` | iOS | `double` | Corner radius for "Yes" confirmation buttons. |
| `iosYesButtonBorderColor` | iOS | `String` | Border color for "Yes" confirmation buttons. |
| `iosNoButtonForeground` | iOS | `String` | Text color for "No" confirmation buttons. |
| `iosNoButtonBackground` | iOS | `String` | Background color for "No" confirmation buttons. |
| `iosNoButtonFont` | iOS | `String` | Custom font name for "No" confirmation buttons. |
| `iosNoButtonFontSize` | iOS | `double` | Font size for "No" confirmation buttons. |
| `iosNoButtonRadius` | iOS | `double` | Corner radius for "No" confirmation buttons. |
| `iosNoButtonBorderColor` | iOS | `String` | Border color for "No" confirmation buttons. |

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
