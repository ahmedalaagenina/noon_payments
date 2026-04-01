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
- 🌍 **Localization**: Native support for English and Arabic.
- 🧪 **Modern API**: Clean, type-safe API using `NoonEnvironment` enums.

---

## 📖 Documentation & SDK Version

- **SDK Version**: 2.1.0 (Android & iOS)
- **Official Documentation**: [docs.noonpayments.com](https://docs.noonpayments.com/)

---

## 🚀 Installation

Add `noon_payments` to your `pubspec.yaml`:

```yaml
dependencies:
  noon_payments: ^0.0.1
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

### 🍎 iOS Setup

1. **Deployment Target**: Ensure your iOS deployment target is at least **13.0**.
2. **Framework Embedding**: In Xcode, ensure the bundled `NoonPaymentsSDK.xcframework` is set to **"Embed & Sign"** under your Runner target's General tab.
3. **CocoaPods**: Run `pod install` in your `ios` directory.

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
  environment: NoonEnvironment.sandbox, // or NoonEnvironment.production
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
  paynowBackgroundColorHighlight: "#4CAF50",
  payableAmountText: "Total to Pay",
);

await NoonPayments.initiatePayment(
  // ... other parameters
  style: customStyle,
);
```

---

## 📖 Style Properties

| Property | Description | Format |
|---|---|---|
| `logoBytes` | Raw bytes for the company logo. | `Uint8List` |
| `backgroundColor` | Background color of the sheet. | `#RRGGBB` |
| `paymentOptionHeadingText` | Title for the payment methods section. | `String` |
| `paymentOptionHeadingForeground`| Color for the payment methods title. | `#RRGGBB` |
| `paymentOptionForeground` | Color for the payment option labels. | `#RRGGBB` |
| `paymentOptionBackground` | Background color of payment options. | `#RRGGBB` |
| `payableBackgroundColor` | Background for the amount section. | `#RRGGBB` |
| `payableAmountText` | Label for the total amount line. | `String` |
| `payableForegroundColor` | Color for the amount text. | `#RRGGBB` |
| `footerText` | Optional text at the very bottom. | `String` |
| `footerForegroundColor` | Color for the footer text. | `#RRGGBB` |
| `addNewCardText` | Label for the "Add Card" button. | `String` |
| `addNewCardTextForegroundColor`| Color for the "Add Card" button text. | `#RRGGBB` |
| `paynowBackgroundColorHighlight`| Color for the "Pay Now" button. | `#RRGGBB` |
| `payNowForegroundColor` | Color for the "Pay Now" button text. | `#RRGGBB` |
| `paynowText` | Label for the "Pay Now" button. | `String` |

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
