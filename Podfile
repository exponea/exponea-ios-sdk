#!/usr/local/bin/ruby -w
project 'ExponeaSDK/ExponeaSDK.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

use_frameworks!

target 'ExponeaSDK' do
  pod 'SwiftSoup', '2.7.6'
end
target 'Example' do
    pod 'SwiftSoup', '2.7.6'
end

target 'ExponeaSDKTests' do
  inherit! :search_paths
  inhibit_all_warnings!

  # Pods for testing
  pod 'Quick', '5.0.1'
  pod 'Nimble', '9.2.1'
  pod 'SwiftLint', '0.51.0'
  pod 'Mockingjay', :git => 'https://github.com/kylef/Mockingjay.git', :branch => 'master'
end


post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
