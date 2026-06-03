## 1.2.0
* Added **Apple Pay on Flutter Web** support. `NoonPayments.payWithApplePay(...)` and `isApplePayAvailable()` now also work on web (Safari/Apple devices) using the browser's `ApplePaySession` API and Noon's 2-step `INITIATE` → `PROCESS_AUTHENTICATION` web flow.
  * **Web supports Apple Pay only** — the drop-in sheet and Google Pay/card flows remain native-mobile only.
* Added `NoonPayments.payWithApplePayServerSide(...)` — backend-delegated web flow (two callbacks) so your Noon key stays off the browser and CORS is avoided. Recommended for production web.
* Web now auto-selects the browser mechanism: `ApplePaySession` in Safari, and the **W3C Payment Request API** in Chrome/Edge — enabling Apple's **cross-device QR** flow (pay on Windows/Android by scanning with an iPhone) where supported. Both reuse the same Noon 2-step flow/callbacks.
* Switched the Apple Pay direct networking from `dart:io` to `package:http` so the package compiles and runs on Flutter Web.
* Made `ApplePayNetwork` and `ApplePayMerchantCapability` extensible (custom values supported).

## 1.1.0
* Added **Apple Pay Direct Integration** (native PassKit sheet) alongside the existing drop-in sheet. Uses Noon's Flow A (Noon decrypts the token — no certificate handling or PCI DSS required).
  * `NoonPayments.isApplePayAvailable()` — device capability check (iOS only).
  * `NoonPayments.getApplePayToken(config)` — present the native Apple Pay sheet and return the token (for backend-side INITIATE).
  * `NoonPayments.payWithApplePay(...)` — present the sheet and submit the token to Noon's INITIATE API from the client.
  * `NoonPayments.submitApplePayToken(...)` — submit an already-collected Apple Pay token to Noon's INITIATE API.
* Added models: `NoonApplePayConfig`, `NoonApplePaySummaryItem`, `NoonApplePayToken`, `NoonOrder`, `NoonOrderItem`, `ApplePayNetwork`, `ApplePayMerchantCapability`.
* Added `NoonPaymentResult.fromInitiateResponse(...)` to parse Noon INITIATE responses.

## 1.0.4+2
* Enhanced parse method to correctly handle data from Noon SDK

## 1.0.4+1
* Updated Android build.gradle to resolve Kapt plugin issue with Kotlin 2.2.20
* Update minimum iOS deployment target to 15.0

## 1.0.3+1
* Fixed iOS Swift Package Manager structure: moved sources under `ios/noon_payments/Sources/noon_payments/` and `Package.swift` to `ios/noon_payments/` so Flutter detects SPM support.
* Declared `FlutterFramework` dependency in `Package.swift` (required by Flutter SPM).
* Updated CocoaPods podspec paths to match the new layout (CocoaPods consumers continue to work).

## 1.0.3
* Added Swift Package Manager (SPM) support for iOS

## 1.0.2
* Fixed R8/ProGuard build error on Android by adding missing Coil dependency and keep rules.

## 1.0.1+2
* Updated README.md.

## 1.0.1
* Added environment param to initiatePayment method to allow the user to add their own environment link.
```dart
environment: NoonEnvironment("YOUR_ENVIRONMENT_LINK"),
```

## 1.0.0+1
* Updated README.md.

## 1.0.0
* Initial release of the Noon Payments Flutter plugin.
* Added Android and iOS payment flow support.
* Added payment result, style, and enum models.
