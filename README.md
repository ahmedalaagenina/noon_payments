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
- 🍏 **Apple Pay Support**: Noon's drop-in sheet, native **Apple Pay Direct Integration** (PassKit), **and Apple Pay on Flutter Web** (Safari `ApplePaySession`).
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
  noon_payments: ^1.2.0
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

In addition to Noon's drop-in payment sheet (`initiatePayment`, which can show Apple Pay as one of its options), this plugin supports Apple Pay's **Direct Integration** on **iOS and Flutter Web**. Your app presents the native Apple Pay sheet (PassKit on iOS, `ApplePaySession` in Safari on Web) and the resulting payment token is submitted to Noon.

> [!CAUTION]
> ## 🌐🌐 ON FLUTTER WEB, THIS PACKAGE SUPPORTS **APPLE PAY ONLY** (FOR NOW) 🌐🌐
>
> The Noon **drop-in payment sheet** (`initiatePayment`) and **Google Pay / card** flows are **native mobile only** and do **NOT** work on Flutter Web. The **only** payment method available on web today is **Apple Pay**, via `NoonPayments.payWithApplePay(...)`.
>
> The package uses **two browser mechanisms automatically**: the native **Apple Pay sheet** in Safari (`ApplePaySession`), and the **W3C Payment Request API** in Chrome/Edge — which surfaces Apple's **cross-device QR flow** (pay on Windows/Android by scanning with an iPhone) where supported. Firefox and browsers without Apple Pay support stay unavailable.

> [!NOTE]
> On **Android**, `isApplePayAvailable()` returns `false` and the Apple Pay methods fail gracefully. Always gate your Apple Pay button on `NoonPayments.isApplePayAvailable()`.

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
final NoonApplePayToken? token = await NoonPayments.getApplePayToken(
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

### 🌐 Apple Pay on the Web (Flutter Web)

> [!CAUTION]
> **Web = Apple Pay only.** The drop-in sheet and Google Pay/card flows do not exist on web. See the big notice at the top of this section.

**Good news: the API is identical.** Call the same `NoonPayments.payWithApplePay(...)` — it automatically uses the right mechanism per platform:

```dart
// This exact code works on BOTH iOS and Flutter Web.
if (await NoonPayments.isApplePayAvailable()) {
  final result = await NoonPayments.payWithApplePay(
    config: NoonApplePayConfig(
      merchantIdentifier: 'merchant.com.yourcompany.app',
      countryCode: 'AE',
      currencyCode: 'AED',
      summaryItems: [NoonApplePaySummaryItem(label: 'Your Business', amount: amount)],
      supportedNetworks: const [ApplePayNetwork.visa, ApplePayNetwork.masterCard, ApplePayNetwork.mada],
    ),
    order: NoonOrder(amount: amount, currency: 'AED', name: 'Test Order', category: 'pay', reference: ref),
    authHeader: 'Key YOUR_AUTHORIZED_KEY',
    environment: NoonEnvironment.production,
  );
  // handle result.isSuccess / isCancelled / isFailed
}
```

#### Browser support & the cross-device QR flow

`payWithApplePay` / `payWithApplePayServerSide` pick the mechanism automatically:

| Browser | Mechanism | Experience |
| :--- | :--- | :--- |
| **Safari** (macOS/iOS) | `ApplePaySession` | Native Apple Pay sheet |
| **Chrome / Edge** (incl. **Windows/Android**) | W3C `PaymentRequest` | Apple's **cross-device QR** — user scans with their iPhone to pay |
| Firefox / others | — | Unavailable (`isApplePayAvailable()` best-effort) |

> [!IMPORTANT]
> The cross-device QR flow depends on **Apple + the browser + your region** all supporting it, and on **Noon enabling the Payment Request API path for your merchant account**. **Confirm with Noon Support** before relying on it in production. On non-Safari browsers `isApplePayAvailable()` is *best-effort* (it returns `true` when `PaymentRequest` exists); the true capability is verified at payment time and the call fails gracefully (`APPLE_PAY_UNAVAILABLE`) if Apple Pay can't actually run.

Under the hood the web flow is the **2-step** Noon process (the iOS native flow is a single call):

```
ApplePaySession (Safari)
   │  onvalidatemerchant ──►  Noon INITIATE  (paymentData.data.validationUrl)  ──►  validationData
   │                          completeMerchantValidation(validationData)
   │  onpaymentauthorized ─►  Noon PROCESS_AUTHENTICATION  (paymentData.data.paymentInfo = token)
   └─ completePayment(status) ──► NoonPaymentResult
```

**Web prerequisites (in addition to the iOS Apple Pay onboarding):**
1. **Register your web domain** with Apple/Noon and host Apple's domain-verification file. Apple Pay JS refuses to run on an unregistered domain.
2. Serve your site over **HTTPS** (required by Apple Pay JS).
3. Call `payWithApplePay` from a **user gesture** (e.g. a button tap) — Safari blocks `ApplePaySession.begin()` otherwise.
4. The order `channel` is automatically sent as `web` for this flow.

> [!WARNING]
> **CORS & key exposure:** `payWithApplePay` on web calls Noon's API **directly from the browser** using your `authHeader`. Noon must allow your origin (CORS), and your key is exposed to the client. **For production web, use the backend-delegated method below instead.**

#### Recommended for production web: route through your backend

`NoonPayments.payWithApplePayServerSide(...)` presents the sheet but lets **your backend** make the two Noon calls (so your key never reaches the browser, and there's no CORS problem). You provide two callbacks:

```dart
final result = await NoonPayments.payWithApplePayServerSide(
  config: NoonApplePayConfig(
    merchantIdentifier: 'merchant.com.yourcompany.app',
    countryCode: 'AE',
    currencyCode: 'AED',
    summaryItems: [NoonApplePaySummaryItem(label: 'Your Business', amount: amount)],
    supportedNetworks: const [ApplePayNetwork.visa, ApplePayNetwork.masterCard, ApplePayNetwork.mada],
  ),

  // 1) Apple asks us to validate the merchant. Send the URL to YOUR server,
  //    which calls Noon INITIATE and returns the `validationData` string.
  onValidateMerchant: (validationUrl) async {
    final res = await http.post(
      Uri.parse('https://your-server.com/apple-pay/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'validationUrl': validationUrl, 'reference': ref}),
    );
    return jsonDecode(res.body)['validationData'] as String;
  },

  // 2) User authorized. Send the token to YOUR server, which calls Noon
  //    PROCESS_AUTHENTICATION and tells you if it succeeded.
  onPaymentAuthorized: (paymentInfo) async {
    final res = await http.post(
      Uri.parse('https://your-server.com/apple-pay/authorize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'paymentInfo': paymentInfo, 'reference': ref}),
    );
    final ok = jsonDecode(res.body)['status'] == 'paid';
    return ok ? NoonPaymentResult.parse(res.body) : NoonPaymentResult.failed(errorMessage: 'Declined');
  },
);
```

Your backend (the two calls Noon documents for the web flow):

```js
// Node.js (Express) — keys stay here, not in the browser.

// (1) Merchant validation → Noon INITIATE with Apple's validation URL.
app.post('/apple-pay/validate', async (req, res) => {
  const { validationUrl, reference } = req.body;
  const order = await db.orders.findByRef(reference); // your trusted amount/items
  const noon = await fetch('https://api.noonpayments.com/payment/v1/order', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Key YOUR_AUTHORIZED_KEY' },
    body: JSON.stringify({
      apiOperation: 'INITIATE',
      order: { amount: order.amount, currency: 'AED', name: 'Test Order', category: 'pay', channel: 'web', reference },
      configuration: { paymentAction: 'AUTHORIZE,SALE' },
      paymentData: { type: 'ApplePay', data: { validationUrl } },
    }),
  }).then(r => r.json());

  await db.orders.attachNoonId(reference, noon.result.order.id); // store for step 2
  res.json({ validationData: noon.result.paymentData.data.validationData });
});

// (2) Payment authorized → Noon PROCESS_AUTHENTICATION with the token.
app.post('/apple-pay/authorize', async (req, res) => {
  const { paymentInfo, reference } = req.body;
  const order = await db.orders.findByRef(reference); // has noon order id from step 1
  const noon = await fetch('https://api.noonpayments.com/payment/v1/order', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Key YOUR_AUTHORIZED_KEY' },
    body: JSON.stringify({
      apiOperation: 'PROCESS_AUTHENTICATION',
      order: { id: order.noonId },
      paymentData: { type: 'ApplePay', data: { paymentInfo } },
    }),
  }).then(r => r.json());

  if (noon.resultCode === 0) return res.json({ status: 'paid', noonOrderId: order.noonId });
  res.json({ status: 'failed', message: noon.message });
});
```

#### How to register your web domain with Apple Pay

Apple Pay JS will silently refuse to run on an unregistered domain. Because Noon manages the certificates (Flow A):

1. Ask **Noon Support** / the Merchant Portal to register your **fully-qualified web domain** (e.g. `web.yoursite.com`) for Apple Pay on the Web.
2. Noon (or Apple) gives you a **domain association file** named `apple-developer-merchantid-domain-association`.
3. Host it at exactly: `https://your-domain/.well-known/apple-developer-merchantid-domain-association` (publicly reachable, **HTTPS**, no redirects).
4. Confirm verification with Noon. Repeat per domain/subdomain you serve the button from.

> The `merchantIdentifier` you pass in `NoonApplePayConfig` must match the one registered for these domains.

### Apple Pay API reference

| Method | Platforms | Returns | Description |
| :--- | :--- | :--- | :--- |
| `NoonPayments.isApplePayAvailable()` | iOS, Web | `Future<bool>` | Whether Apple Pay can be used (`false` on Android & non-Safari browsers). |
| `NoonPayments.payWithApplePay(...)` | iOS, Web | `Future<NoonPaymentResult>` | Presents the sheet **and** submits to Noon from the client. Single-call on iOS, 2-step on web. |
| `NoonPayments.payWithApplePayServerSide(...)` | Web only | `Future<NoonPaymentResult>` | Presents the sheet; your **backend** makes the two Noon calls via callbacks (recommended for production web). |
| `NoonPayments.getApplePayToken(config)` | iOS only | `Future<NoonApplePayToken?>` | Presents the native sheet; returns the token (for backend-side INITIATE). |
| `NoonPayments.submitApplePayToken(...)` | iOS, Web¹ | `Future<NoonPaymentResult>` | Submits an already-collected `token` to Noon's INITIATE API. |

¹ Networking works on web, but the standalone token flow is the mobile (single-call) shape; on web use `payWithApplePay`.

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
