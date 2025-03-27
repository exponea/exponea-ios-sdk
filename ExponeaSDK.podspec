#
#  Be sure to run `pod spec lint exponea-ios-sdk.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "ExponeaSDK"
  s.version      = "3.2.0"
  s.summary      = "Exponea SDK used to track and fetch data from Exponea Experience Cloud."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  This library allows you to interact from your application or game with the Exponea App.
  Exponea empowers B2C marketers to raise conversion rates, improve acquisition ROI, and maximize customer lifetime value.
                   DESC

  s.homepage     = "https://github.com/exponea/exponea-ios-sdk"
  s.readme       = "https://github.com/exponea/exponea-ios-sdk/blob/main/README.md"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "MIT"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "Exponea" => "info@exponea.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  s.platform     = :ios, "13.0"
  s.swift_versions = ['4.2.0', '5.0', '5.6.1', '5.7', '5.8', '5.8.1', '5.9', '5.10']

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/exponea/exponea-ios-sdk.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = [
    "ExponeaSDK/ExponeaSDK/**/*.swift",
    "ExponeaSDK/ExponeaSDK/**/*.storyboard",
    "ExponeaSDK/ExponeaSDK/**/*.xcassets",
    "ExponeaSDK/ExponeaSDKShared/**/*.swift",
    "ExponeaSDK/ExponeaSDKObjC/objc_tryCatch.h",
    "ExponeaSDK/ExponeaSDKObjC/objc_tryCatch.m",
  ]
  s.resource_bundles = {'ExponeaSDK' => ['ExponeaSDK/ExponeaSDK/Supporting Files/PrivacyInfo.xcprivacy']}
  s.exclude_files = "ExponeaSDK/ExponeaSDK-Notifications/**/*"
  s.resources = ["ExponeaSDK/ExponeaSDK/Classes/Database/*.xcdatamodeld"]
  s.dependency 'SwiftSoup', '2.6.1'
  
end
