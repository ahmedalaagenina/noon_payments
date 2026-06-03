import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../models/noon_apple_pay.dart';
import '../models/noon_payment_result.dart';

// ---------------------------------------------------------------------------
// Apple Pay JS API (ApplePaySession) — Safari only. Used as a fallback.
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

extension type _PaymentAuthorizedEvent._(JSObject _) implements JSObject {
  external _ApplePayPayment get payment;
}

extension type _ApplePayPayment._(JSObject _) implements JSObject {
  external JSObject get token;
}

// ---------------------------------------------------------------------------
// W3C Payment Request API (Apple Pay method) — Safari AND Chrome/Edge. This is
// the path that shows Apple's cross-device QR code on non-Safari desktops.
// Mirrors Apple's own demo: https://applepaydemo.apple.com/payment-request-api
// ---------------------------------------------------------------------------

@JS('PaymentRequest')
extension type _PaymentRequest._(JSObject _) implements JSObject {
  external _PaymentRequest(JSArray methodData, JSObject details);
  external JSPromise<_PaymentResponse> show();
  external set onmerchantvalidation(JSFunction value);
}

extension type _MerchantValidationEvent._(JSObject _) implements JSObject {
  external String get validationURL;
  external void complete(JSAny merchantSessionPromise);
}

extension type _PaymentResponse._(JSObject _) implements JSObject {
  external JSObject get details;
  external JSPromise complete(String result);
}

@JS('JSON.stringify')
external String _jsonStringify(JSObject value);

@JS('JSON.parse')
external JSObject _jsonParse(String text);

// ---------------------------------------------------------------------------
// Public surface (mirrors apple_pay_web_stub.dart).
// ---------------------------------------------------------------------------

/// Whether Apple Pay can (likely) be used in this browser.
///
/// - Browsers with the W3C `PaymentRequest` API (Safari, Chrome, Edge) return
///   `true` — this is **best-effort**, since the real capability (and the
///   cross-device QR) is only confirmed when the sheet is shown.
/// - Older Safari without `PaymentRequest` uses `ApplePaySession`.
bool applePayWebAvailable() {
  if (globalContext.has('PaymentRequest')) return true;
  if (globalContext.has('ApplePaySession')) {
    try {
      return _ApplePaySession.canMakePayments();
    } catch (_) {}
  }
  return false;
}

/// Core Apple Pay on the Web runner. Prefers the **Payment Request API** (works
/// in Safari and Chrome/Edge, and shows the cross-device QR on non-Safari
/// desktops); falls back to `ApplePaySession` on older Safari.
///
/// The two Noon calls are delegated to the callbacks:
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
  if (globalContext.has('PaymentRequest')) {
    return _runViaPaymentRequest(
      config: config,
      onValidateMerchant: onValidateMerchant,
      onPaymentAuthorized: onPaymentAuthorized,
    );
  }

  if (globalContext.has('ApplePaySession')) {
    var canUse = false;
    try {
      canUse = _ApplePaySession.canMakePayments();
    } catch (_) {}
    if (canUse) {
      return _runViaApplePaySession(
        config: config,
        onValidateMerchant: onValidateMerchant,
        onPaymentAuthorized: onPaymentAuthorized,
      );
    }
  }

  return Future.value(NoonPaymentResult.failed(
    errorCode: 'APPLE_PAY_UNAVAILABLE',
    errorMessage: 'Apple Pay is not available in this browser.',
  ));
}

/// Payment Request API path (Safari + Chrome/Edge, incl. cross-device QR).
Future<NoonPaymentResult> _runViaPaymentRequest({
  required NoonApplePayConfig config,
  required Future<String> Function(String validationUrl) onValidateMerchant,
  required Future<NoonPaymentResult> Function(String paymentInfo)
      onPaymentAuthorized,
}) async {
  final methodData = [
    {
      'supportedMethods': 'https://apple.com/apple-pay',
      'data': {
        'version': 3,
        'merchantIdentifier': config.merchantIdentifier,
        'merchantCapabilities': _mapCapabilities(config.merchantCapabilities),
        'supportedNetworks':
            config.supportedNetworks.map((e) => e.value).toList(),
        'countryCode': config.countryCode,
      },
    },
  ].jsify() as JSArray;

  final items = config.summaryItems;
  final total = items.isNotEmpty
      ? items.last
      : const NoonApplePaySummaryItem(label: 'Total', amount: '0');
  final displayItems = items.length > 1
      ? items.sublist(0, items.length - 1)
      : const <NoonApplePaySummaryItem>[];

  final details = {
    'total': {
      'label': total.label,
      'amount': {'currency': config.currencyCode, 'value': total.amount},
    },
    if (displayItems.isNotEmpty)
      'displayItems': displayItems
          .map((e) => {
                'label': e.label,
                'amount': {'currency': config.currencyCode, 'value': e.amount},
              })
          .toList(),
  }.jsify() as JSObject;

  final _PaymentRequest request;
  try {
    request = _PaymentRequest(methodData, details);
  } catch (e) {
    return NoonPaymentResult.failed(
      errorCode: 'SESSION_ERROR',
      errorMessage: 'Could not create the Payment Request: $e',
    );
  }

  // Merchant validation → delegate to the caller (which hits your backend),
  // then resolve Apple's event with the parsed merchant session.
  request.onmerchantvalidation = ((JSObject event) {
    final validationUrl = (event as _MerchantValidationEvent).validationURL;
    final sessionPromise = (() async {
      final validationData = await onValidateMerchant(validationUrl);
      return _jsonParse(validationData);
    })()
        .toJS;
    event.complete(sessionPromise);
  }).toJS;

  // IMPORTANT: do NOT gate on canMakePayment(). For the cross-device QR the
  // desktop itself cannot pay, so canMakePayment() returns false even though
  // show() correctly displays the "Scan Code with iPhone" code.
  final _PaymentResponse response;
  try {
    response = await request.show().toDart;
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('abort')) {
      return NoonPaymentResult.cancelled();
    }
    return NoonPaymentResult.failed(
      errorCode: 'APPLE_PAY_UNAVAILABLE',
      errorMessage: 'Apple Pay could not be shown in this browser: $e',
    );
  }

  final token = response.details.getProperty<JSObject?>('token'.toJS);
  if (token == null) {
    try {
      await response.complete('fail').toDart;
    } catch (_) {}
    return NoonPaymentResult.failed(
      errorCode: 'NO_TOKEN',
      errorMessage: 'Apple Pay returned no payment token.',
    );
  }

  final wrapper = JSObject();
  wrapper.setProperty('token'.toJS, token);
  final paymentInfo = _jsonStringify(wrapper);

  NoonPaymentResult result;
  try {
    result = await onPaymentAuthorized(paymentInfo);
  } catch (e) {
    result = NoonPaymentResult.failed(
      errorCode: 'PROCESS_AUTH_FAILED',
      errorMessage: e.toString(),
    );
  }

  try {
    await response.complete(result.isSuccess ? 'success' : 'fail').toDart;
  } catch (_) {}

  return result;
}

/// Apple Pay JS API path (older Safari without Payment Request).
Future<NoonPaymentResult> _runViaApplePaySession({
  required NoonApplePayConfig config,
  required Future<String> Function(String validationUrl) onValidateMerchant,
  required Future<NoonPaymentResult> Function(String paymentInfo)
      onPaymentAuthorized,
}) {
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
    session = _ApplePaySession(version, _buildApplePaySessionRequest(config));
  } catch (e) {
    return Future.value(NoonPaymentResult.failed(
      errorCode: 'SESSION_ERROR',
      errorMessage: 'Could not create the Apple Pay session: $e',
    ));
  }

  void complete(NoonPaymentResult result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  session.onvalidatemerchant = ((JSObject event) {
    final validationUrl = (event as _MerchantValidationEvent).validationURL;
    () async {
      try {
        final validationData = await onValidateMerchant(validationUrl);
        session.completeMerchantValidation(_jsonParse(validationData));
      } catch (e) {
        session.abort();
        complete(NoonPaymentResult.failed(
          errorCode: 'MERCHANT_VALIDATION_FAILED',
          errorMessage: e.toString(),
        ));
      }
    }();
  }).toJS;

  session.onpaymentauthorized = ((JSObject event) {
    final token = (event as _PaymentAuthorizedEvent).payment.token;
    () async {
      final wrapper = JSObject();
      wrapper.setProperty('token'.toJS, token);
      final paymentInfo = _jsonStringify(wrapper);

      NoonPaymentResult result;
      try {
        result = await onPaymentAuthorized(paymentInfo);
      } catch (e) {
        result = NoonPaymentResult.failed(
          errorCode: 'PROCESS_AUTH_FAILED',
          errorMessage: e.toString(),
        );
      }

      final completeArg = JSObject();
      completeArg.setProperty(
        'status'.toJS,
        (result.isSuccess
                ? _ApplePaySession.statusSuccess
                : _ApplePaySession.statusFailure)
            .toJS,
      );
      session.completePayment(completeArg);
      complete(result);
    }();
  }).toJS;

  session.oncancel = ((JSObject event) {
    complete(NoonPaymentResult.cancelled());
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

JSObject _buildApplePaySessionRequest(NoonApplePayConfig config) {
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
