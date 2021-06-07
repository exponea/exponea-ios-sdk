#!/usr/local/bin/ruby -w
project 'ExponeaSDK/ExponeaSDK.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'ExponeaSDKTests' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # target 'ExponeaSDKTests' do
    inherit! :search_paths

    inhibit_all_warnings!

    # Pods for testing
    pod 'Quick'
    pod 'Nimble', '~>9.2.0'
    pod 'SwiftLint'
    pod 'Mockingjay'
  # end
end
