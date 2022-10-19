#!/usr/local/bin/ruby -w
project 'ExponeaSDK/ExponeaSDK.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '10.3'

use_frameworks!

target 'ExponeaSDKTests' do
    inherit! :search_paths

    inhibit_all_warnings!

    # Pods for testing
    pod 'Quick'
    pod 'Nimble', '~>9.2.0'
    pod 'SwiftLint'
    pod 'Mockingjay', :git => 'https://github.com/kylef/Mockingjay.git', :branch => 'master'
end
