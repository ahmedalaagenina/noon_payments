import Foundation
import Flutter
import PassKit

/// Presents the native Apple Pay sheet (PassKit) and returns the resulting
/// payment token to Flutter, for the Noon Apple Pay "Direct Integration" flow.
class NoonApplePayHandler: NSObject {

    private var pendingResult: FlutterResult?
    private var controller: PKPaymentAuthorizationController?
    private var didAuthorize = false

    /// Whether the device can make Apple Pay payments.
    func canMakePayments() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }

    /// Presents the Apple Pay sheet using the supplied configuration.
    func present(args: [String: Any], result: @escaping FlutterResult) {
        // Guard against a second presentation while one is in flight.
        if pendingResult != nil {
            result(FlutterError(code: "IN_PROGRESS",
                                message: "An Apple Pay request is already in progress.",
                                details: nil))
            return
        }

        guard PKPaymentAuthorizationController.canMakePayments() else {
            result(FlutterError(code: "APPLE_PAY_UNAVAILABLE",
                                message: "This device cannot make Apple Pay payments.",
                                details: nil))
            return
        }

        guard let merchantId = args["merchantIdentifier"] as? String,
              let countryCode = args["countryCode"] as? String,
              let currencyCode = args["currencyCode"] as? String,
              let summaryItems = args["summaryItems"] as? [[String: Any]],
              let networkStrings = args["supportedNetworks"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                                message: "Missing or invalid Apple Pay configuration.",
                                details: nil))
            return
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantId
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        request.supportedNetworks = mapNetworks(networkStrings)
        request.merchantCapabilities = mapCapabilities(args["merchantCapabilities"] as? [String])
        request.paymentSummaryItems = mapSummaryItems(summaryItems)

        if request.paymentSummaryItems.isEmpty {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                                message: "At least one payment summary item is required.",
                                details: nil))
            return
        }

        self.pendingResult = result
        self.didAuthorize = false

        let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentController.delegate = self
        self.controller = paymentController
        paymentController.present(completion: { presented in
            if !presented {
                self.finish(with: FlutterError(
                    code: "PRESENTATION_FAILED",
                    message: "Unable to present the Apple Pay sheet. Check that the "
                        + "Apple Pay capability is enabled for your app target in Xcode "
                        + "(Signing & Capabilities), that your Merchant ID is selected "
                        + "there and matches merchantIdentifier ('\(merchantId)'), and "
                        + "that a supported card is set up in Wallet on this device.",
                    details: nil))
            }
        })
    }

    // MARK: - Mapping helpers

    private func mapNetworks(_ values: [String]) -> [PKPaymentNetwork] {
        var networks: [PKPaymentNetwork] = []
        for value in values {
            switch value.lowercased() {
            case "visa": networks.append(.visa)
            case "mastercard": networks.append(.masterCard)
            case "amex": networks.append(.amex)
            case "discover": networks.append(.discover)
            case "maestro":
                if #available(iOS 12.0, *) { networks.append(.maestro) }
            case "jcb": networks.append(.JCB)
            case "mada":
                if #available(iOS 12.1.1, *) { networks.append(.mada) }
            default:
                // Forward-compat: pass custom/unknown values straight through.
                // The string must match Apple's exact PKPaymentNetwork raw value.
                networks.append(PKPaymentNetwork(value))
            }
        }
        return networks
    }

    private func mapCapabilities(_ values: [String]?) -> PKMerchantCapability {
        guard let values = values, !values.isEmpty else { return .capability3DS }
        var capabilities: PKMerchantCapability = []
        for value in values {
            switch value.lowercased() {
            case "3ds": capabilities.insert(.capability3DS)
            case "emv": capabilities.insert(.capabilityEMV)
            case "credit": capabilities.insert(.capabilityCredit)
            case "debit": capabilities.insert(.capabilityDebit)
            default: break
            }
        }
        return capabilities.isEmpty ? .capability3DS : capabilities
    }

    private func mapSummaryItems(_ items: [[String: Any]]) -> [PKPaymentSummaryItem] {
        return items.compactMap { item in
            guard let label = item["label"] as? String,
                  let amountString = item["amount"] as? String,
                  let amount = Decimal(string: amountString) else {
                return nil
            }
            return PKPaymentSummaryItem(label: label,
                                        amount: NSDecimalNumber(decimal: amount))
        }
    }

    private func paymentMethodTypeString(_ type: PKPaymentMethodType) -> String {
        switch type {
        case .debit: return "debit"
        case .credit: return "credit"
        case .prepaid: return "prepaid"
        case .store: return "store"
        default: return "unknown"
        }
    }

    /// Resolves the pending Flutter result exactly once.
    private func finish(with value: Any?) {
        pendingResult?(value)
        pendingResult = nil
        controller = nil
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension NoonApplePayHandler: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        didAuthorize = true
        let token = payment.token

        var paymentDataObject: Any = [:]
        if let decoded = try? JSONSerialization.jsonObject(with: token.paymentData, options: []) {
            paymentDataObject = decoded
        }

        var paymentMethod: [String: Any] = [
            "type": paymentMethodTypeString(token.paymentMethod.type)
        ]
        if let displayName = token.paymentMethod.displayName {
            paymentMethod["displayName"] = displayName
        }
        if let network = token.paymentMethod.network {
            paymentMethod["network"] = network.rawValue
        }

        let tokenDict: [String: Any] = [
            "paymentData": paymentDataObject,
            "paymentMethod": paymentMethod,
            "transactionIdentifier": token.transactionIdentifier
        ]

        let payload: [String: Any] = [
            "token": tokenDict,
            "network": token.paymentMethod.network?.rawValue as Any,
            "displayName": token.paymentMethod.displayName as Any
        ]

        finish(with: payload)
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        controller.dismiss(completion: nil)
        // If the sheet was dismissed without authorizing, treat as cancellation.
        if !didAuthorize {
            finish(with: nil)
        }
    }
}
