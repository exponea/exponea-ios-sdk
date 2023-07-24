#!/usr/local/bin/ruby -w
project 'ExponeaSDK/ExponeaSDK.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

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


post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
               end
          end
   end
end
