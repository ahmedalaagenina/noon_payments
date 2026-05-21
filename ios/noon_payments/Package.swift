// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "noon_payments",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "noon-payments",
            targets: ["noon_payments"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "noon_payments",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .target(name: "NoonPaymentsSDK")
            ]
        ),
        .binaryTarget(
            name: "NoonPaymentsSDK",
            path: "NoonPaymentsSDK.xcframework"
        )
    ]
)
