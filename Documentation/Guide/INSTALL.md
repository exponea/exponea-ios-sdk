## Installation

There are two ways of installing Exponea SDK for iOS.

### Carthage

1. Open `Cartfile` file located in your project folder
2. Add ExponeaSDK dependency  
`github "exponea/exponea-ios-sdk`
3. Run the Carthage update command  
`carthage update exponea-ios-sdk`

### CocoaPods

1. Open `Podfile` file located in your project folder
2. Add ExponeaSDK dependency  
`pod 'ExponeaSDK'`
3. Install the dependency  
`pod install`


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
		authorization: .token("YOUR ACCESS TOKEN")
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
