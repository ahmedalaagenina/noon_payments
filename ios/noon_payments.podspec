#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint noon_payments.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'noon_payments'
  s.version          = '1.0.1+1'
  s.summary          = 'A Flutter plugin for integrating Noon Payments SDK on Android and iOS.'
  s.description      = <<-DESC
A Flutter plugin for integrating the Noon Payments SDK on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/ahmedalaagenina/noon_payments'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Ahmed Alaa Genina'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'NoonPaymentsSDK.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'noon_payments_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
