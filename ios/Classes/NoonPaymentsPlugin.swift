import UIKit
import Flutter
import NoonPaymentsSDK

extension UIColor {
    static func fromHex(_ hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }
        if cString.count != 6 { return UIColor.gray }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

public class NoonPaymentsPlugin: NSObject, FlutterPlugin, NoonPaymentDelegate {
    private var pendingResult: FlutterResult?
    private var noonPayments: NoonPayments?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "noon_payments", binaryMessenger: registrar.messenger())
        let instance = NoonPaymentsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "startPayment" {
            guard let args = call.arguments as? [String: Any],
                  let orderId = args["orderId"] as? String,
                  let authHeader = args["authHeader"] as? String,
                  let urlString = args["url"] as? String,
                  let url = URL(string: urlString) else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
                return
            }
            
            self.pendingResult = result
            
            var request = PaymentRequest()
            request.orderId = orderId
            request.authHeader = authHeader
            request.url = url
            
            var styleConfig = StyleConfiguration()
            
            if let bgHex = args["backgroundColor"] as? String {
                styleConfig.backgroundColor = UIColor.fromHex(bgHex)
            }
            if let logoBytes = args["logoBytes"] as? FlutterStandardTypedData {
                styleConfig.frameworkLogo = UIImage(data: logoBytes.data)
            }
            if let headingText = args["paymentOptionHeadingText"] as? String {
                styleConfig.paymentOptionsHeadingText = headingText
            }
            if let headingFg = args["paymentOptionHeadingForeground"] as? String {
                styleConfig.paymentOptionsHeadingForeground = UIColor.fromHex(headingFg)
            }
            if let optionText = args["paymentOptionText"] as? String {
                styleConfig.paymentOptionText = optionText
            }
            if let optionFg = args["paymentOptionForeground"] as? String {
                styleConfig.paymentOptionForeground = UIColor.fromHex(optionFg)
            }
            if let optionBg = args["paymentOptionBackground"] as? String {
                styleConfig.paymentOptionBackground = UIColor.fromHex(optionBg)
            }
            if let payableBg = args["payableBackgroundColor"] as? String {
                styleConfig.payableAreaBackground = UIColor.fromHex(payableBg)
            }
            if let payableText = args["payableAmountText"] as? String {
                styleConfig.payableAmountText = payableText
            }
            if let payableFg = args["payableAmountForeground"] as? String {
                styleConfig.payableAmountForeground = UIColor.fromHex(payableFg)
            }
            if let footerText = args["footerText"] as? String {
                styleConfig.footerText = footerText
            }
            if let footerFg = args["footerForegroundColor"] as? String {
                styleConfig.footerForeground = UIColor.fromHex(footerFg)
            }
            if let addNText = args["addNewCardText"] as? String {
                styleConfig.addNewCardText = addNText
            }
            if let addNFg = args["addNewCardTextForegroundColor"] as? String {
                styleConfig.addNewCardForeground = UIColor.fromHex(addNFg)
            }
            if let payBg = args["paynowBackgroundColorHighlight"] as? String {
                styleConfig.payNowButtonBackground = UIColor.fromHex(payBg)
            }
            if let payFg = args["payNowForegroundColor"] as? String {
                styleConfig.payNowButtonForeground = UIColor.fromHex(payFg)
            }
            if let payText = args["paynowText"] as? String {
                styleConfig.payNowButtonText = payText
            }
            
            var rootViewController: UIViewController?
            if #available(iOS 13.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                rootViewController = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
                
                // Fallback if no key window is found
                if rootViewController == nil {
                    rootViewController = windowScene?.windows.first?.rootViewController
                }
            }
            
            if rootViewController == nil {
                rootViewController = UIApplication.shared.keyWindow?.rootViewController
            }
            
            // Final fallback to the application's root window from the delegate
            if rootViewController == nil {
                rootViewController = UIApplication.shared.windows.first?.rootViewController
            }
            
            guard let controller = rootViewController else {
                result(FlutterError(code: "VIEW_ERROR", message: "Could not find root view controller", details: nil))
                return
            }
            
            self.noonPayments = NoonPayments()
            self.noonPayments?.startPaymentWith(request: request, styleConfig: styleConfig, delegate: self, baseController: controller)
            
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - NoonPaymentDelegate
    public func showLoaderForProcessingPayment(showLoader: Bool) {
        // Nothing needed here, the native UI handles its own loader usually
    }
    
    public func paymentCompleted(response: PaymentResponse) {
        var json: [String: Any] = [
            "orderId": response.orderId,
            "amount": response.amount,
            "currency": response.currency,
            "orderStatus": response.orderStatus.rawValue
        ]
        
        if let err = response.error {
            json["message"] = err.message
            json["resultCode"] = err.resultCode
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            self.pendingResult?(jsonString)
        } else {
            self.pendingResult?("")
        }
        
        self.pendingResult = nil
        self.noonPayments = nil
    }
}
