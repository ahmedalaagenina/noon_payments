import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:http/http.dart' as http;

import '../models/noon_apple_pay.dart';
import '../models/noon_payment_enums.dart';
import '../models/noon_payment_result.dart';

// ---------------------------------------------------------------------------
// JavaScript interop bindings for the Safari "Apple Pay on the Web" API.
// See: https://developer.apple.com/documentation/apple_pay_on_the_web
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

// --- W3C Payment Request API (Apple Pay as a payment method). Enables the
// cross-device QR flow on Chrome/Edge, including Windows/Android. ---

@JS('PaymentRequest')
extension type _PaymentRequest._(JSObject _) implements JSObject {
  external _PaymentRequest(JSArray methodData, JSObject details);
  external JSPromise<JSBoolean> canMakePayment();
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

/// Whether Apple Pay can (likely) be used in this browser.
///
/// - In **Safari** (`ApplePaySession`) this is a precise check.
/// - In **other browsers** that expose the W3C `PaymentRequest` API (Chrome,
///   Edge — including Windows/Android), this is **best-effort**: the real
///   capability (and the cross-device QR flow) is only confirmed at payment
///   time via `PaymentRequest.canMakePayment()`.
bool applePayWebAvailable() {
  if (globalContext.has('ApplePaySession')) {
    try {
      if (_ApplePaySession.canMakePayments()) return true;
    } catch (_) {}
  }
  // Payment Request API may offer Apple Pay (incl. cross-device QR).
  return globalContext.has('PaymentRequest');
}

/// Core Apple Pay on the Web runner. Picks the best browser mechanism and
/// delegates the two Noon calls to the supplied callbacks:
///
/// - [onValidateMerchant] receives Apple's `validationURL` and must return the
///   `validationData` (merchant session string) — typically by calling Noon
///   `INITIATE` (directly or via your backend).
/// - [onPaymentAuthorized] receives the stringified Apple Pay token
///   (`paymentInfo`) and must return the final [NoonPaymentResult] — typically
///   by calling Noon `PROCESS_AUTHENTICATION` (directly or via your backend).
///
/// Uses `ApplePaySession` on Safari, otherwise falls back to the W3C
/// `PaymentRequest` API (which enables the cross-device QR flow).
Future<NoonPaymentResult> runApplePayWebSession({
  required NoonApplePayConfig config,
  required Future<String> Function(String validationUrl) onValidateMerchant,
  required Future<NoonPaymentResult> Function(String paymentInfo)
      onPaymentAuthorized,
}) {
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

  if (globalContext.has('PaymentRequest')) {
    return _runViaPaymentRequest(
      config: config,
      onValidateMerchant: onValidateMerchant,
      onPaymentAuthorized: onPaymentAuthorized,
    );
  }

  return Future.value(NoonPaymentResult.failed(
    errorCode: 'APPLE_PAY_UNAVAILABLE',
    errorMessage: 'Apple Pay is not available in this browser.',
  ));
}

/// Apple Pay JS API path (Safari on Apple devices).
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

  // Step 1 → merchant validation.
  session.onvalidatemerchant = ((JSObject event) {
    final validationUrl = (event as _ValidateMerchantEvent).validationURL;
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

  // Step 2 → payment authorized.
  session.onpaymentauthorized = ((JSObject event) {
    final token = (event as _PaymentAuthorizedEvent).payment.token;
    () async {
      // Build { "token": <PKPaymentToken> } to match `paymentData.data.paymentInfo`.
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

/// W3C Payment Request API path. Works in non-Safari browsers (Chrome/Edge,
/// including Windows/Android) and surfaces Apple's cross-device **QR** flow
/// when supported.
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
  final displayItems =
      items.length > 1 ? items.sublist(0, items.length - 1) : const [];

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

  // Merchant validation → delegate to the caller, resolve with the session.
  request.onmerchantvalidation = ((JSObject event) {
    final validationUrl = (event as _MerchantValidationEvent).validationURL;
    final sessionPromise = () async {
      final validationData = await onValidateMerchant(validationUrl);
      return _jsonParse(validationData);
    }()
        .toJS;
    event.complete(sessionPromise);
  }).toJS;

  // Confirm the browser can actually pay with Apple Pay.
  try {
    final canPay = (await request.canMakePayment().toDart).toDart;
    if (!canPay) {
      return NoonPaymentResult.failed(
        errorCode: 'APPLE_PAY_UNAVAILABLE',
        errorMessage: 'This browser cannot make Apple Pay payments.',
      );
    }
  } catch (e) {
    return NoonPaymentResult.failed(
      errorCode: 'APPLE_PAY_UNAVAILABLE',
      errorMessage: 'Apple Pay is not available here: $e',
    );
  }

  final _PaymentResponse response;
  try {
    response = await request.show().toDart;
  } catch (_) {
    // The user dismissed the sheet/QR (AbortError) or it could not be shown.
    return NoonPaymentResult.cancelled();
  }

  // The Apple Pay token is carried on response.details (the ApplePayPayment).
  final token = response.details.getProperty('token'.toJS) as JSObject;
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

/// All-in-one web flow: presents the sheet and calls Noon **directly from the
/// browser** (both INITIATE and PROCESS_AUTHENTICATION) using [authHeader].
Future<NoonPaymentResult> runApplePayWebDirect({
  required NoonApplePayConfig config,
  required NoonOrder order,
  required String authHeader,
  required NoonEnvironment environment,
  String paymentAction = 'AUTHORIZE,SALE',
}) {
  String? orderId;
  return runApplePayWebSession(
    config: config,
    onValidateMerchant: (validationUrl) async {
      final (id, validationData) = await _initiateWeb(
        order: order,
        authHeader: authHeader,
        environment: environment,
        paymentAction: paymentAction,
        validationUrl: validationUrl,
      );
      orderId = id;
      return validationData;
    },
    onPaymentAuthorized: (paymentInfo) {
      return _processAuthentication(
        orderId: orderId!,
        authHeader: authHeader,
        environment: environment,
        paymentInfo: paymentInfo,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

JSObject _buildPaymentRequest(NoonApplePayConfig config) {
  final items = config.summaryItems;
  final total = items.isNotEmpty
      ? items.last
      : const NoonApplePaySummaryItem(label: 'Total', amount: '0');
  final lineItems =
      items.length > 1 ? items.sublist(0, items.length - 1) : const [];

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

Map<String, String> _headers(String authHeader) => {
      'Content-Type': 'application/json',
      'Authorization': authHeader,
    };

/// Web step 1 — INITIATE with the Apple validation URL.
/// Returns `(orderId, validationData)`.
Future<(String, String)> _initiateWeb({
  required NoonOrder order,
  required String authHeader,
  required NoonEnvironment environment,
  required String paymentAction,
  required String validationUrl,
}) async {
  final body = {
    'apiOperation': 'INITIATE',
    'order': order.toMap()..['channel'] = 'web',
    'configuration': {'paymentAction': paymentAction},
    'paymentData': {
      'type': 'ApplePay',
      'data': {'validationUrl': validationUrl},
    },
  };

  final response = await http.post(
    Uri.parse(environment.url),
    headers: _headers(authHeader),
    body: jsonEncode(body),
  );

  final parsed = jsonDecode(response.body) as Map<String, dynamic>;
  final rawCode = parsed['resultCode'];
  final code = rawCode is int ? rawCode : int.tryParse('$rawCode');
  if (code != 0) {
    throw Exception(parsed['message']?.toString() ??
        'INITIATE failed (resultCode: $rawCode)');
  }

  final result = parsed['result'] as Map<String, dynamic>?;
  final orderId = result?['order']?['id']?.toString();
  final validationData =
      result?['paymentData']?['data']?['validationData'] as String?;

  if (orderId == null || validationData == null) {
    throw Exception('INITIATE response missing order id or validationData.');
  }
  return (orderId, validationData);
}

/// Web step 2 — PROCESS_AUTHENTICATION with the Apple Pay token.
Future<NoonPaymentResult> _processAuthentication({
  required String orderId,
  required String authHeader,
  required NoonEnvironment environment,
  required String paymentInfo,
}) async {
  final body = {
    'apiOperation': 'PROCESS_AUTHENTICATION',
    'order': {'id': orderId},
    'paymentData': {
      'type': 'ApplePay',
      'data': {'paymentInfo': paymentInfo},
    },
  };

  final response = await http.post(
    Uri.parse(environment.url),
    headers: _headers(authHeader),
    body: jsonEncode(body),
  );

  return NoonPaymentResult.fromInitiateResponse(response.body);
}
