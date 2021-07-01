## Installation

There are two ways of installing Exponea SDK for iOS.

### Carthage

1. Open `Cartfile` file located in your project folder
2. Add ExponeaSDK dependency  
`github "exponea/exponea-ios-sdk"`
3. Run the Carthage update command  
`carthage update exponea-ios-sdk --use-xcframeworks`
4. On your application targets’ General settings tab, in the Frameworks, Libraries, and Embedded Content section, drag and drop every XCFramework from the Carthage/Build folder on disk.

### CocoaPods

1. Open `Podfile` file located in your project folder
2. Add ExponeaSDK dependency  
`pod 'ExponeaSDK'`
3. Install the dependency  
`pod install`

### Swift Package Manager
To see available GitHub packages, you have to add your GitHub account in Preferences -> Accounts.
Instructions are written for XCode 12.5.

1. In XCode, go to File -> Swift Packages -> Add Package Dependency – a new window will open. 
2. Search for `exponea-ios-sdk` and click next.
3. Pick the desired version and click next again. 
4. Pick packages you want to include. If you want to use push notifications, make sure you selected also `ExponeaSDK-Notifications`.
5. Hit the finish button. 

## Initializing Exponea
In order to use ExponeaSDK you have to initialize and configure it first.

You can configure you Exponea instance either in code or using
`.plist` configuration file. Minimal configuration requires you to provide `Authorization Token`, `Project Token` and `Base URL`. 

You can find these parameters in **Exponea Web App**.
> [How do I get these parameters?](./CONFIGURATION.md)


##### Using code
```swift
Exponea.shared.configure(
	Exponea.ProjectSettings(
		projectToken: "YOUR PROJECT TOKEN",
		authorization: .token("YOUR ACCESS TOKEN"),
		baseUrl: "https://api.exponea.com"
	),
	pushNotificationTracking: .disabled
)
```

##### Using a configuration file

You can also use `.plist` file in order to provide your configuration. Feel free to save this file anywhere in the root of your main bundle.

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>projectToken</key>
	<string> MyProjectToken </string>
	<key>authorization</key>
	<string>Token authorizationToken</string>
	<key>baseUrl</key>
	<string>https://api.exponea.com</string>
</dict>
</plist>

```

Then in your code you can initialize Exponea while using that file by writing the following.

```
// Plist name being the filename of the configuration file
Exponea.share.configure(plistName: "Exponea.plist")
```

> [Learn more about how you can configure ExponeaSDK](../CONFIG.md)
