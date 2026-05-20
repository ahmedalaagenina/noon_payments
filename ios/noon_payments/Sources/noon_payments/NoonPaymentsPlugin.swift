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
            
            // Payment Option Heading
            if let text = args["paymentOptionHeadingText"] as? String {
                styleConfig.paymentOptionsHeadingText = text
            }
            if let fgHex = args["paymentOptionHeadingForeground"] as? String {
                styleConfig.paymentOptionsHeadingForeground = UIColor.fromHex(fgHex)
            }
            if let fontName = args["iosPaymentOptionHeadingFont"] as? String {
                let fontSize = args["iosPaymentOptionHeadingFontSize"] as? Double ?? 17.0
                styleConfig.paymentOptionsHeadingFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }

            // Payment Option Tabs
            if let text = args["paymentOptionText"] as? String {
                styleConfig.paymentOptionText = text
            }
            if let fgHex = args["paymentOptionForeground"] as? String {
                styleConfig.paymentOptionForeground = UIColor.fromHex(fgHex)
            }
            if let bgHex = args["paymentOptionBackground"] as? String {
                styleConfig.paymentOptionBackground = UIColor.fromHex(bgHex)
            }
            if let borderHex = args["iosPaymentOptionBorderColor"] as? String {
                styleConfig.paymentOptionBorderColor = UIColor.fromHex(borderHex)
            }
            if let fontName = args["iosPaymentOptionFont"] as? String {
                let fontSize = args["iosPaymentOptionFontSize"] as? Double ?? 14.0
                styleConfig.paymentOptionFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }

            // Payable Amount
            if let bgHex = args["payableAreaBackground"] as? String {
                styleConfig.payableAreaBackground = UIColor.fromHex(bgHex)
            }
            if let text = args["payableAmountText"] as? String {
                styleConfig.payableAmountText = text
            }
            if let fgHex = args["payableAmountForeground"] as? String {
                styleConfig.payableAmountForeground = UIColor.fromHex(fgHex)
            }
            if let fontName = args["iosPayableAmountFont"] as? String {
                let fontSize = args["iosPayableAmountFontSize"] as? Double ?? 16.0
                styleConfig.payableAmountFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }

            // Footer
            if let text = args["footerText"] as? String {
                styleConfig.footerText = text
            }
            if let fgHex = args["footerForeground"] as? String {
                styleConfig.footerForeground = UIColor.fromHex(fgHex)
            }
            if let fontName = args["iosFooterFont"] as? String {
                let fontSize = args["iosFooterFontSize"] as? Double ?? 12.0
                styleConfig.footerFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }

            // Add New Card
            if let text = args["addNewCardText"] as? String {
                styleConfig.addNewCardText = text
            }
            if let fgHex = args["addNewCardForeground"] as? String {
                styleConfig.addNewCardForeground = UIColor.fromHex(fgHex)
            }
            if let fontName = args["iosAddNewCardFont"] as? String {
                let fontSize = args["iosAddNewCardFontSize"] as? Double ?? 14.0
                styleConfig.addNewCardFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }

            // Pay Now Button
            if let bgHex = args["payNowButtonBackground"] as? String {
                styleConfig.payNowButtonBackground = UIColor.fromHex(bgHex)
            }
            if let fgHex = args["payNowButtonForeground"] as? String {
                styleConfig.payNowButtonForeground = UIColor.fromHex(fgHex)
            }
            if let text = args["payNowButtonText"] as? String {
                styleConfig.payNowButtonText = text
            }
            if let fontName = args["iosPayNowButtonFont"] as? String {
                let fontSize = args["iosPayNowButtonFontSize"] as? Double ?? 16.0
                styleConfig.payNowButtonFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }
            if let radius = args["iosPayNowButtonRadius"] as? Double {
                styleConfig.payNowButtonRadius = CGFloat(radius)
            }

            // Yes/No Buttons styling (iOS Only)
            if let fgHex = args["iosYesButtonForeground"] as? String {
                styleConfig.yesButtonForeground = UIColor.fromHex(fgHex)
            }
            if let bgHex = args["iosYesButtonBackground"] as? String {
                styleConfig.yesButtonBackground = UIColor.fromHex(bgHex)
            }
            if let fontName = args["iosYesButtonFont"] as? String {
                let fontSize = args["iosYesButtonFontSize"] as? Double ?? 14.0
                styleConfig.yesButtonFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }
            if let radius = args["iosYesButtonRadius"] as? Double {
                styleConfig.yesButtonRadius = CGFloat(radius)
            }
            if let borderHex = args["iosYesButtonBorderColor"] as? String {
                styleConfig.yesButtonBorderColor = UIColor.fromHex(borderHex)
            }

            if let fgHex = args["iosNoButtonForeground"] as? String {
                styleConfig.noButtonForeground = UIColor.fromHex(fgHex)
            }
            if let bgHex = args["iosNoButtonBackground"] as? String {
                styleConfig.noButtonBackground = UIColor.fromHex(bgHex)
            }
            if let fontName = args["iosNoButtonFont"] as? String {
                let fontSize = args["iosNoButtonFontSize"] as? Double ?? 14.0
                styleConfig.noButtonFont = UIFont(name: fontName, size: CGFloat(fontSize))
            }
            if let radius = args["iosNoButtonRadius"] as? Double {
                styleConfig.noButtonRadius = CGFloat(radius)
            }
            if let borderHex = args["iosNoButtonBorderColor"] as? String {
                styleConfig.noButtonBorderColor = UIColor.fromHex(borderHex)
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
