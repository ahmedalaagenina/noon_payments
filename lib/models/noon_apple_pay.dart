import 'dart:convert';

/// Card networks that can be offered in the native Apple Pay sheet.
///
/// Use the predefined constants ([visa], [masterCard], [mada], …) for the
/// common networks. To support a network Apple has added but this package does
/// not yet expose, pass a custom value:
///
/// ```dart
/// ApplePayNetwork('Jaywan') // must match Apple's exact PKPaymentNetwork raw value
/// ```
///
/// > Custom values are forwarded straight to `PKPaymentNetwork(rawValue:)` on
/// > iOS, so they must use Apple's exact spelling/casing (e.g. `"Jaywan"`).
/// > The predefined constants below are case-insensitive.
///
/// To accept **mada** cards, make sure [mada] is included.
class ApplePayNetwork {
  /// The identifier sent to the native platform.
  final String value;

  /// Creates a network identifier. Prefer the predefined constants; use this
  /// only for networks not yet exposed by the package.
  const ApplePayNetwork(this.value);

  /// Visa
  static const ApplePayNetwork visa = ApplePayNetwork('visa');

  /// Mastercard
  static const ApplePayNetwork masterCard = ApplePayNetwork('masterCard');

  /// American Express
  static const ApplePayNetwork amex = ApplePayNetwork('amex');

  /// mada (Saudi domestic network)
  static const ApplePayNetwork mada = ApplePayNetwork('mada');

  /// Maestro
  static const ApplePayNetwork maestro = ApplePayNetwork('maestro');

  /// Discover
  static const ApplePayNetwork discover = ApplePayNetwork('discover');

  /// JCB
  static const ApplePayNetwork jcb = ApplePayNetwork('jcb');

  @override
  bool operator ==(Object other) =>
      other is ApplePayNetwork && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ApplePayNetwork($value)';
}

/// Merchant capabilities advertised to Apple Pay.
///
/// Defaults to [threeDSecure] which is required by Noon for processing. Use the
/// predefined constants; a custom value can be supplied for forward
/// compatibility, but only capabilities Apple recognizes are applied natively.
class ApplePayMerchantCapability {
  /// The identifier sent to the native platform.
  final String value;

  /// Creates a capability identifier. Prefer the predefined constants.
  const ApplePayMerchantCapability(this.value);

  /// Support for the 3-D Secure protocol (required by Noon).
  static const ApplePayMerchantCapability threeDSecure =
      ApplePayMerchantCapability('3DS');

  /// Support for the EMV protocol.
  static const ApplePayMerchantCapability emv =
      ApplePayMerchantCapability('EMV');

  /// Support for credit cards.
  static const ApplePayMerchantCapability credit =
      ApplePayMerchantCapability('Credit');

  /// Support for debit cards.
  static const ApplePayMerchantCapability debit =
      ApplePayMerchantCapability('Debit');

  @override
  bool operator ==(Object other) =>
      other is ApplePayMerchantCapability && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ApplePayMerchantCapability($value)';
}

/// A single line shown in the native Apple Pay payment sheet.
///
/// Following Apple's convention, the **last** item in the list is treated as
/// the grand total and its [label] is usually the merchant/business name.
class NoonApplePaySummaryItem {
  /// The text shown to the user (e.g. an item name or the business name).
  final String label;

  /// The amount as a decimal string (e.g. `"10"` or `"10.50"`).
  final String amount;

  const NoonApplePaySummaryItem({required this.label, required this.amount});

  /// Serializes the item for the method channel.
  Map<String, dynamic> toMap() => {'label': label, 'amount': amount};
}

/// Configuration used to present the **native** Apple Pay sheet (PassKit).
///
/// This is required for the direct Apple Pay integration where the merchant
/// app collects the Apple Pay token itself instead of using Noon's drop-in
/// payment sheet.
class NoonApplePayConfig {
  /// Your Apple Pay merchant identifier, e.g. `merchant.com.yourcompany.app`.
  ///
  /// Must match the Merchant ID configured in your Apple Developer account
  /// and onboarded in the Noon Merchant Portal.
  final String merchantIdentifier;

  /// ISO 3166-1 alpha-2 country code of the merchant (e.g. `"AE"`, `"SA"`).
  final String countryCode;

  /// ISO 4217 currency code (e.g. `"AED"`, `"SAR"`). Should match the order.
  final String currencyCode;

  /// Lines shown in the Apple Pay sheet. The last item is the grand total.
  final List<NoonApplePaySummaryItem> summaryItems;

  /// Card networks to accept. Include [ApplePayNetwork.mada] for mada cards.
  final List<ApplePayNetwork> supportedNetworks;

  /// Merchant capabilities. Defaults to [ApplePayMerchantCapability.threeDSecure].
  final List<ApplePayMerchantCapability> merchantCapabilities;

  const NoonApplePayConfig({
    required this.merchantIdentifier,
    required this.countryCode,
    required this.currencyCode,
    required this.summaryItems,
    this.supportedNetworks = const [
      ApplePayNetwork.visa,
      ApplePayNetwork.masterCard,
      ApplePayNetwork.mada,
    ],
    this.merchantCapabilities = const [
      ApplePayMerchantCapability.threeDSecure,
    ],
  });

  /// Serializes the config for the method channel.
  Map<String, dynamic> toMap() => {
    'merchantIdentifier': merchantIdentifier,
    'countryCode': countryCode,
    'currencyCode': currencyCode,
    'summaryItems': summaryItems.map((e) => e.toMap()).toList(),
    'supportedNetworks': supportedNetworks.map((e) => e.value).toList(),
    'merchantCapabilities': merchantCapabilities.map((e) => e.value).toList(),
  };
}

/// The Apple Pay token returned by the native PassKit sheet after the user
/// authorizes the payment.
///
/// The token is sent as-is to Noon, which decrypts it (no certificate handling
/// on your side). Use [paymentInfo] for the value that goes into
/// `paymentData.data.paymentInfo`.
class NoonApplePayToken {
  /// The full PassKit token object:
  /// `{ "paymentData": {...}, "paymentMethod": {...}, "transactionIdentifier": "..." }`.
  final Map<String, dynamic> token;

  /// The network of the selected card (e.g. `"Visa"`, `"MasterCard"`, `"Mada"`).
  final String? network;

  /// A human-readable description of the card (e.g. `"MasterCard 3569"`).
  final String? displayName;

  const NoonApplePayToken({
    required this.token,
    this.network,
    this.displayName,
  });

  /// Builds a [NoonApplePayToken] from the native method channel result.
  factory NoonApplePayToken.fromMap(Map<dynamic, dynamic> map) {
    return NoonApplePayToken(
      token: Map<String, dynamic>.from(map['token'] as Map),
      network: map['network'] as String?,
      displayName: map['displayName'] as String?,
    );
  }

  /// The stringified value used for `paymentData.data.paymentInfo` in the
  /// INITIATE request.
  String get paymentInfo => jsonEncode({'token': token});

  /// The raw token map, suitable for forwarding to your own backend if you
  /// prefer to call INITIATE server-side.
  Map<String, dynamic> toMap() => {
    'token': token,
    'network': network,
    'displayName': displayName,
  };
}

/// A line item attached to a Noon order.
class NoonOrderItem {
  /// Item name.
  final String name;

  /// Quantity of the item.
  final int quantity;

  /// Unit price of the item.
  final num unitPrice;

  const NoonOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  /// Serializes the item for the INITIATE request.
  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

/// The order details sent to Noon's INITIATE API.
class NoonOrder {
  /// Total amount as a decimal string (e.g. `"10"`). Must be greater than zero.
  final String amount;

  /// ISO 4217 currency code (e.g. `"AED"`).
  final String currency;

  /// Short description of the order. No leading/trailing or consecutive spaces.
  final String name;

  /// Pre-configured order route category (e.g. `"pay"`).
  final String category;

  /// Merchant's internal order reference (optional, max 50 chars).
  final String? reference;

  /// Traffic channel. Defaults to `"mobile"` for the direct Apple Pay flow.
  final String channel;

  /// Optional line items. Their total should match [amount].
  final List<NoonOrderItem>? items;

  const NoonOrder({
    required this.amount,
    required this.currency,
    required this.name,
    required this.category,
    this.reference,
    this.channel = 'mobile',
    this.items,
  });

  /// Serializes the order for the INITIATE request.
  Map<String, dynamic> toMap() => {
    'amount': amount,
    'currency': currency,
    'name': name,
    'category': category,
    'channel': channel,
    if (reference != null) 'reference': reference,
    if (items != null) 'items': items!.map((e) => e.toMap()).toList(),
  };
}
