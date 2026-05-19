// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "noon_payments",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "noon-payments",
            targets: ["noon_payments"]
        )
    ],
    targets: [
        .target(
            name: "noon_payments",
            dependencies: [
                .target(name: "NoonPaymentsSDK")
            ],
            path: "Classes"
        ),
        .binaryTarget(
            name: "NoonPaymentsSDK",
            path: "NoonPaymentsSDK.xcframework"
        )
    ]
)
