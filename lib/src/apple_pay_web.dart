import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../models/noon_apple_pay.dart';
import '../models/noon_payment_result.dart';

// ---------------------------------------------------------------------------
// Apple Pay on the Web via the `ApplePaySession` API.
//
// In Safari this API is built in. In other browsers (Chrome/Edge, incl.
// Windows) it becomes available — and shows Apple's cross-device QR — only when
// the host page loads Apple's JS SDK:
//
//   <script crossorigin
//     src="https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js"></script>
//
// See: https://developer.apple.com/documentation/applepayontheweb
// ---------------------------------------------------------------------------

@JS('ApplePaySession')
extension type _ApplePaySession._(JSObject _) implements JSObject {
  external _ApplePaySession(int version, JSObject paymentRequest);

  external static bool canMakePayments();
  external static bool supportsVersion(int version);
  @JS('STATUS_SUCCESS')
  external static int get statusSuccess;
  @JS('STATUS_FAILURE')
  external static int get statusFailure;

  external void begin();
  external void abort();
  external void completeMerchantValidation(JSObject merchantSession);
  external void completePayment(JSObject result);

  external set onvalidatemerchant(JSFunction value);
  external set onpaymentauthorized(JSFunction value);
  external set oncancel(JSFunction value);
}

extension type _ValidateMerchantEvent._(JSObject _) implements JSObject {
  external String get validationURL;
}

extension type _PaymentAuthorizedEvent._(JSObject _) implements JSObject {
  external _ApplePayPayment get payment;
}

extension type _ApplePayPayment._(JSObject _) implements JSObject {
  external JSObject get token;
}

@JS('JSON.stringify')
external String _jsonStringify(JSObject value);

@JS('JSON.parse')
external JSObject _jsonParse(String text);

// ---------------------------------------------------------------------------
// Public surface (mirrors apple_pay_web_stub.dart).
// ---------------------------------------------------------------------------

/// Whether Apple Pay can be used in this browser.
///
/// `true` in Safari (native), and in Chrome/Edge **when Apple's JS SDK script
/// is loaded** in `web/index.html`. `false` otherwise.
bool applePayWebAvailable() {
  if (!globalContext.has('ApplePaySession')) return false;
  try {
    return _ApplePaySession.canMakePayments();
  } catch (_) {
    return false;
  }
}

/// Runs the Apple Pay on the Web flow via `ApplePaySession`, delegating the two
/// Noon calls to the callbacks:
///
/// - [onValidateMerchant] receives Apple's `validationURL` and must return the
///   `validationData` (merchant session string) — your backend calls Noon
///   `INITIATE` and returns `result.paymentData.data.validationData`.
/// - [onPaymentAuthorized] receives the stringified Apple Pay token
///   (`paymentInfo`) and must return the final [NoonPaymentResult] — your
///   backend calls Noon `PROCESS_AUTHENTICATION`.
Future<NoonPaymentResult> runApplePayWebSession({
  required NoonApplePayConfig config,
  required Future<String> Function(String validationUrl) onValidateMerchant,
  required Future<NoonPaymentResult> Function(String paymentInfo)
      onPaymentAuthorized,
}) {
  if (!globalContext.has('ApplePaySession')) {
    return Future.value(NoonPaymentResult.failed(
      errorCode: 'APPLE_PAY_SDK_MISSING',
      errorMessage: 'Apple Pay is unavailable in this browser. Safari has it '
          'built in; for other browsers add Apple\'s JS SDK to web/index.html: '
          '<script crossorigin src="https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js"></script>',
    ));
  }

  final completer = Completer<NoonPaymentResult>();

  // Pick the highest mutually supported version (fall back to 3).
  var version = 3;
  for (final v in [6, 5, 4, 3]) {
    try {
      if (_ApplePaySession.supportsVersion(v)) {
        version = v;
        break;
      }
    } catch (_) {}
  }

  final _ApplePaySession session;
  try {
    session = _ApplePaySession(version, _buildPaymentRequest(config));
  } catch (e) {
    return Future.value(NoonPaymentResult.failed(
      errorCode: 'SESSION_ERROR',
      errorMessage: 'Could not create the Apple Pay session: $e',
    ));
  }

  void complete(NoonPaymentResult result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  void abortSession() {
    try {
      session.abort();
    } catch (_) {}
  }

  // Step 1 → merchant validation (your backend calls Noon INITIATE).
  // NOTE: these JS event handlers must NEVER throw into the SDK — a thrown
  // error breaks the SDK's modal handling (e.g. the "Continue on iPhone" sheet
  // would not dismiss). So every path is wrapped.
  session.onvalidatemerchant = ((JSObject event) {
    () async {
      try {
        final validationUrl =
            (event as _ValidateMerchantEvent).validationURL;
        final validationData = await onValidateMerchant(validationUrl);
        session.completeMerchantValidation(_jsonParse(validationData));
      } catch (e) {
        abortSession();
        complete(NoonPaymentResult.failed(
          errorCode: 'MERCHANT_VALIDATION_FAILED',
          errorMessage: e.toString(),
        ));
      }
    }();
  }).toJS;

  // Step 2 → payment authorized (your backend calls Noon PROCESS_AUTHENTICATION).
  session.onpaymentauthorized = ((JSObject event) {
    () async {
      NoonPaymentResult result;
      try {
        // Build { "token": <PKPaymentToken> } for `paymentData.data.paymentInfo`.
        final token = (event as _PaymentAuthorizedEvent).payment.token;
        final wrapper = JSObject();
        wrapper.setProperty('token'.toJS, token);
        result = await onPaymentAuthorized(_jsonStringify(wrapper));
      } catch (e) {
        result = NoonPaymentResult.failed(
          errorCode: 'PROCESS_AUTH_FAILED',
          errorMessage: e.toString(),
        );
      }

      try {
        final completeArg = JSObject();
        completeArg.setProperty(
          'status'.toJS,
          (result.isSuccess
                  ? _ApplePaySession.statusSuccess
                  : _ApplePaySession.statusFailure)
              .toJS,
        );
        session.completePayment(completeArg);
      } catch (_) {}
      complete(result);
    }();
  }).toJS;

  session.oncancel = ((JSObject event) {
    try {
      complete(NoonPaymentResult.cancelled());
    } catch (_) {}
  }).toJS;

  try {
    session.begin();
  } catch (e) {
    complete(NoonPaymentResult.failed(
      errorCode: 'BEGIN_FAILED',
      errorMessage: 'Could not start the Apple Pay session: $e',
    ));
  }

  return completer.future;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

JSObject _buildPaymentRequest(NoonApplePayConfig config) {
  final items = config.summaryItems;
  final total = items.isNotEmpty
      ? items.last
      : const NoonApplePaySummaryItem(label: 'Total', amount: '0');
  final lineItems = items.length > 1
      ? items.sublist(0, items.length - 1)
      : const <NoonApplePaySummaryItem>[];

  final request = <String, dynamic>{
    'countryCode': config.countryCode,
    'currencyCode': config.currencyCode,
    'supportedNetworks': config.supportedNetworks.map((e) => e.value).toList(),
    'merchantCapabilities': _mapCapabilities(config.merchantCapabilities),
    'total': {'label': total.label, 'amount': total.amount, 'type': 'final'},
    if (lineItems.isNotEmpty)
      'lineItems': lineItems
          .map((e) => {'label': e.label, 'amount': e.amount, 'type': 'final'})
          .toList(),
  };

  return request.jsify() as JSObject;
}

/// Maps the package's capability identifiers to Apple's JS web naming.
List<String> _mapCapabilities(List<ApplePayMerchantCapability> caps) {
  final out = <String>[];
  for (final c in caps) {
    switch (c.value.toUpperCase()) {
      case '3DS':
        out.add('supports3DS');
        break;
      case 'EMV':
        out.add('supportsEMV');
        break;
      case 'CREDIT':
        out.add('supportsCredit');
        break;
      case 'DEBIT':
        out.add('supportsDebit');
        break;
    }
  }
  if (out.isEmpty) out.add('supports3DS');
  return out;
}
