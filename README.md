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
- 🌍 **Localization**: Native support for English and Arabic.
- 🧪 **Modern API**: Clean, type-safe API using `NoonEnvironment` enums.

---

## 📖 Documentation & SDK Version

- **SDK Version**: 2.1.0 (Android & iOS)
- **Official Documentation**: [docs.noonpayments.com](https://docs.noonpayments.com/)

---

## 🚀 Installation

### 1. GitHub Dependency

Since the plugin is hosted on GitHub, add it to your `pubspec.yaml` like this:

```yaml
dependencies:
  noon_payments:
    git:
      url: git@github.com:ahmedalaagenina/noon_payments.git
      ref: main # or specify a tag/branch
```

> [!TIP]
> **No manual SDK download is required.** The plugin comes pre-bundled with the Noon Payments native libraries (`.aar` for Android and `.xcframework` for iOS).

---

## 🛠️ Platform Setup

### 🤖 Android Setup

1. **Enable Data Binding**: Since the Noon SDK uses Data Binding, you must enable it in your **app-level** `android/app/build.gradle`:
   ```gradle
   android {
       buildFeatures {
           dataBinding true
       }
   }
   ```
2. **Google Pay Metadata**: Add the following inside your `<application>` tag in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.wallet.api.enabled"
       android:value="true" />
   ```

### 🍎 iOS Setup & Apple Pay

1. **Deployment Target**: Ensure your iOS deployment target is at least **13.0**.
2. **Framework Embedding**: In Xcode, ensure the bundled `NoonPaymentsSDK.xcframework` is set to **"Embed & Sign"** under your Runner target's General tab.
3. **Apple Pay Capabilities**: To enable Apple Pay, you must configure your Apple Developer account and Xcode:
   - Go to your [Apple Developer Portal](https://developer.apple.com/).
   - Create a new **Merchant ID** (e.g., `merchant.com.yourcompany.app`).
   - Open your project in **Xcode**.
   - Go to your target's **Signing & Capabilities** tab.
   - Click `+ Capability` and add **Apple Pay**.
   - Check the box next to the Merchant ID you created.
4. **Noon Dashboard Configuration**:
   - Ensure your Backend sends **YOUR** valid `merchantIdentifier` in your server-side call (do not use Noon's default sandbox merchant ID).
   - Ensure Mobile SDK is activated in your Noon Payments Dashboard (You Can Contact Noon Support).

---

## 💳 Usage

### ⚙️ 1. Generate Order ID (Server-Side)
Before launching the payment sheet, your backend **must** call Noon's `INITIATE` API. 

> [!IMPORTANT]
> You **MUST** set the `returnUrl` correctly in your server-side call for the SDK to return the user to your app:
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
  // environment: NoonEnvironment.custom("[https://api-test.sa.noonpayments.com/payment/v1/order](https://api-test.sa.noonpayments.com/payment/v1/order)"),

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

| Property                         | Platform |    Type     | Description                                      |
| :------------------------------- | :------: | :---------: | :----------------------------------------------- |
| `logoBytes`                      |   Both   | `Uint8List` | Company logo image bytes.                        |
| `backgroundColor`                |   Both   |  `String`   | Background color of the sheet (`#RRGGBB`).       |
| `paymentOptionHeadingText`       |   Both   |  `String`   | Title text for the methods section.              |
| `paymentOptionHeadingForeground` |   Both   |  `String`   | Color for the methods section title.             |
| `paymentOptionText`              |   Both   |  `String`   | Label for payment method tabs.                   |
| `paymentOptionForeground`        |   Both   |  `String`   | Text color for payment method tabs.              |
| `paymentOptionBackground`        |   Both   |  `String`   | Background color for payment method tabs.        |
| `payableAreaBackground`          |   Both   |  `String`   | Background color for the amount area.            |
| `payableAmountText`              |   Both   |  `String`   | Label for the payable amount (e.g. "Total").     |
| `payableAmountForeground`        |   Both   |  `String`   | Text color for the amount display.               |
| `footerText`                     |   Both   |  `String`   | Footer text at the bottom.                       |
| `footerForeground`               |   Both   |  `String`   | Text color for the footer text.                  |
| `addNewCardText`                 |   Both   |  `String`   | Label for the "Add New Card" button.             |
| `addNewCardForeground`           |   Both   |  `String`   | Text color for the "Add New Card" label.         |
| `payNowButtonBackground`         |   Both   |  `String`   | Background color for the "Pay Now" button.       |
| `payNowButtonForeground`         |   Both   |  `String`   | Text color for the "Pay Now" button.             |
| `payNowButtonText`               |   Both   |  `String`   | Label for the "Pay Now" button.                  |
| `iosPaymentOptionHeadingFont`    |   iOS    |  `String`   | Custom font name for the section heading.        |
| `iosPaymentOptionBorderColor`    |   iOS    |  `String`   | Border color for method tabs.                    |
| `iosPayNowButtonRadius`          |   iOS    |  `double`   | Corner radius for the "Pay Now" button.          |
| `iosYesButtonBackground`         |   iOS    |  `String`   | Background color for "Yes" confirmation buttons. |
| `iosNoButtonBackground`          |   iOS    |  `String`   | Background color for "No" confirmation buttons.  |

> [!NOTE]
> This is a partial list. All property names starting with `ios` (e.g., `iosPaymentOptionFont`, `iosYesButtonRadius`, `iosNoButtonBorderColor`) are exclusively for iOS as per the Noon iOS SDK capabilities. Following the "Rule of Truth", unified names apply to both platforms where supported.

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
