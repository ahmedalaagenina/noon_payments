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
- 🍏 **Apple Pay Support**: Both Noon's drop-in sheet **and** a native **Apple Pay Direct Integration** (PassKit).
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
  noon_payments: ^1.1.0
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

## 🍏 Apple Pay (Direct Integration)

In addition to Noon's drop-in payment sheet (`initiatePayment`, which can show Apple Pay as one of its options), this plugin supports Apple Pay's **Direct Integration**. Here your app presents the **native** Apple Pay sheet (via Apple's PassKit) and the resulting payment token is submitted to Noon's `INITIATE` API.

> [!NOTE]
> Apple Pay is **iOS-only**. On Android, `isApplePayAvailable()` returns `false` and the pay methods fail gracefully — gate your Apple Pay button on `NoonPayments.isApplePayAvailable()`.

### How it works

```
Native Apple Pay sheet (PassKit)  →  Apple Pay token  →  Noon INITIATE API  →  Result
```

The token Apple hands you is **encrypted**, and someone has to decrypt it to charge the card. Noon documents two ways to do this:

- **Flow A:** get the token from Apple → send the (encrypted) token to Noon → **Noon decrypts it** and charges. ✅
- **Flow B:** get the token from Apple → send it to your backend → **your backend decrypts it** (using your own certificate) → send the decrypted fields to Noon → Noon charges. ✅

Think of it like a **locked box**:

- **Flow A** → you hand the locked box to Noon, and **Noon has the key**.
- **Flow B** → **you have the key**, so you open the box yourself and hand Noon what's inside.

> [!NOTE]
> **This plugin uses Flow A** — so you never touch a payment certificate and you don't need PCI DSS compliance. Flow B (merchant-managed certificate) requires PCI DSS SAQ-D and must be implemented on your own backend; it is **not** handled by this plugin.

### Prerequisites

1. Complete the **iOS Setup & Apple Pay** steps above (Merchant ID, Apple Pay capability, payment processing certificate exchanged between Apple and the Noon Dashboard).
2. Ensure your order **category** is configured to route through the `mobile` channel — contact Noon Support.
3. To accept **mada** cards, include `ApplePayNetwork.mada` in `supportedNetworks`.

### Option 1 — Convenience: present + INITIATE from the client

Easiest path; consistent with `initiatePayment` (uses your `authHeader` on the device).

```dart
import 'package:noon_payments/noon_payments.dart';

// 1. Only show the Apple Pay button if the device supports it.
final bool canUseApplePay = await NoonPayments.isApplePayAvailable();

// 2. Present the native sheet and submit the token to Noon.
final result = await NoonPayments.payWithApplePay(
  config: const NoonApplePayConfig(
    merchantIdentifier: 'merchant.com.yourcompany.app', // YOUR Merchant ID
    countryCode: 'AE',
    currencyCode: 'AED',
    summaryItems: [
      // The LAST item is the grand total; its label is usually your business name.
      NoonApplePaySummaryItem(label: 'Your Business', amount: '10'),
    ],
    supportedNetworks: [
      ApplePayNetwork.visa,
      ApplePayNetwork.masterCard,
      ApplePayNetwork.mada, // required to accept mada cards
    ],
  ),
  order: const NoonOrder(
    amount: '10',
    currency: 'AED',
    name: 'Test Order',
    category: 'pay',
    reference: 'NPORDTEST0001',
    // channel defaults to 'mobile'
  ),
  authHeader: 'Key YOUR_AUTHORIZED_KEY',
  environment: NoonEnvironment.sandbox, // or .production / a custom regional URL
  paymentAction: 'AUTHORIZE,SALE',       // AUTHORIZE | SALE | AUTHORIZE,SALE
);

if (result.isSuccess) {
  print('✅ Apple Pay successful! ${result.data}');
} else if (result.isCancelled) {
  print('🚫 User cancelled Apple Pay.');
} else {
  print('❌ Failed: ${result.errorMessage} (Code: ${result.errorCode})');
}
```

### Option 2 — Most secure: present on device, INITIATE on your backend

Keeps your authorization key **off the device**. The plugin only presents Apple Pay and hands you the token; your server calls `INITIATE`.

```dart
final NoonApplePayToken? token = await NoonPayments.presentApplePay(
  const NoonApplePayConfig(
    merchantIdentifier: 'merchant.com.yourcompany.app',
    countryCode: 'AE',
    currencyCode: 'AED',
    summaryItems: [NoonApplePaySummaryItem(label: 'Your Business', amount: '10')],
  ),
);

if (token == null) {
  // User cancelled the sheet.
} else {
  // Send token.paymentInfo to your backend. Your server then POSTs to
  // https://api.noonpayments.com/payment/v1/order with:
  //   "paymentData": { "type": "ApplePay", "data": { "paymentInfo": "<token.paymentInfo>" } }
  await myBackend.completeApplePay(paymentInfo: token.paymentInfo);
}
```

### Apple Pay API reference

| Method | Returns | Description |
| :--- | :--- | :--- |
| `NoonPayments.isApplePayAvailable()` | `Future<bool>` | Whether the device can pay with Apple Pay (always `false` off iOS). |
| `NoonPayments.presentApplePay(config)` | `Future<NoonApplePayToken?>` | Presents the native sheet; returns the token, or `null` if cancelled. |
| `NoonPayments.payWithApplePay(...)` | `Future<NoonPaymentResult>` | Presents the sheet **and** submits the token to Noon's INITIATE API from the client. |
| `NoonPayments.initiateApplePayOrder(...)` | `Future<NoonPaymentResult>` | Submits an already-collected `token` to Noon's INITIATE API. |

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
