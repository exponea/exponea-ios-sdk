---
title: App Inbox
excerpt: Add a message inbox to your app using the iOS SDK
slug: ios-sdk-app-inbox
categorySlug: integrations
parentDocSlug: ios-sdk
---

The App Inbox feature adds a mobile communication channel directly in the app. The App Inbox can receive messages sent by campaigns and store mobile push notifications for a defined period. Note that the SDK can only fetch App Inbox messages if the current app user has a customer profile identified by a [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#hard-id).

Refer to the [App Inbox](https://documentation.bloomreach.com/engagement/docs/app-inbox) documentation for information on creating and sending App Inbox messages in the Engagement web app.

> 👍
>
> App Inbox is a separate module that can be enabled on request in your Engagement account by your Bloomreach CSM.

## Integrate the App Inbox

You can integrate the App Inbox through a button provided by the SDK, which opens the App Inbox messages list view.

![App Inbox button](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/app-inbox-button.png)

Use the `getAppInboxButton()` method to retrieve the button:

```swift
let button = Exponea.shared.getAppInboxButton()
```

You can then add the button anywhere in your app. For example:

```swift
class FetchViewController: UIViewController {

    @IBOutlet var buttonsStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let button = Exponea.shared.getAppInboxButton()
        self.buttonsStack.addArrangedSubview(button)
    }

    // ...
}
```

> ❗️
>
> The SDK must be initialized before you can retrieve the App Inbox button.

> ❗️
>
> Always check the retrieved App Inbox button for null value.

That's all that's required to integrate the App Inbox. Optionally, you can [customize](#customize-app-inbox) it to your needs.

> 📘
>
> See [FetchViewController](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Fetching/FetchViewController.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a reference implementation.

## Default App Inbox Behavior

The SDK fetches and displays the App Inbox automatically as follows:

1. Display a button to access the App Inbox messages list view (integration by developer).
2. Display a messages list view. Display each item with:
   - Flag indicating whether the message is read or unread.
   - Delivery time in human-readable form (for example, `2 hours ago`).
   - Single-lined title of the message (ended by '...' for longer values).
   - Two-lined content of the message (ended by '...' for longer values).
   - Squared image if the message contains any.
   - Loading progress indicator of the list.
   - Empty Inbox title and message in case there are no messages.
   - Error title and description in case of an error loading the list
3. Call `Exponea.shared.trackAppInboxOpened` when the user clicks on a list item and mark the message as read automatically.
4. Display a message detail view that contains:
   - Large squared image (or a gray placeholder if the message doesn't contain an image).
   - Delivery time in human-readable form (for example, `2 hours ago`).
   - Full title of the message.
   - Full content of the message.
   - A button for each action in the message that opens a browser link or invokes a universal link. No button is displayed for an action that opens the current app.
5. Call `Exponea.shared.trackAppInboxClick` automatically when the user clicks a button in the message detail view.


![App Inbox messages list view and message detail view](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/app-inbox.png)

> ❗️
>
> Note that the SDK can only fetch App Inbox messages if the current app user has a customer profile identified by a [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#hard-id).

> ❗️
>
> The behavior of `trackAppInboxOpened` and `trackAppInboxClick` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Refer to [Consent](https://dash.readme.com/project/bloomreachengagement/v2/docs/ios-sdk-tracking-consent) for details.

## Customize App Inbox

Although the App Inbox works out of the box once the button has been integrated in your app, you may want to customize it to your app's requirements.

### Localization

The SDK provides the following UI labels in English. You can modify these or add localized labels by defining customized strings in your `Localizable.string` files.

```text
"exponea.inbox.button" = "Inbox";
"exponea.inbox.title" = "AppInbox";
"exponea.inbox.emptyTitle" = "Empty Inbox";
"exponea.inbox.emptyMessage" = "You have no messages yet.";
"exponea.inbox.errorTitle" = "Something went wrong :(";
"exponea.inbox.errorMessage" = "We could not retrieve your messages.";
"exponea.inbox.defaultTitle" = "Message";
"exponea.inbox.mainActionTitle" = "See more";
```

### Customize UI Components

You can override App Inbox UI elements by registering your own `AppInboxProvider` implementation:

```swift
Exponea.shared.appInboxProvider = ExampleAppInboxProvider()
```

You may register your provider anytime - before or after SDK initialization. Every action in scope of the App Inbox is using the currently registered provider instance. However, we recommend you register your provider directly after SDK initialization.

Your `AppInboxProvider` instance must implement all App Inbox UI components. You can extend from the SDK's `DefaultAppInboxProvider` and override only the UI views you want to customize.

> 📘
>
> Refer to [ExampleAppInboxProvider](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/ExampleAppInboxProvider.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a reference implementation.

#### App Inbox Button

The method `getAppInboxButton()` returns a `UIButton` instance.

The default implementation builds a simple button instance with an icon ![Inbox icon](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/inbox.png) and the `exponea.inbox.button` label. The click action for the button opens the App Inbox list view.

To customize this behavior, override `getAppInboxButton()`. For example:

```swift
public override func getAppInboxButton() -> UIButton {
   // reuse a default button or create your own
   let button = super.getAppInboxButton()
   // apply your setup
   button.backgroundColor = UIColor(red: 255/255, green: 213/255, blue: 0/255, alpha: 1.0)
   button.layer.cornerRadius = 4
   button.setTitleColor(.black, for: .normal)
   button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
   // return instance
   return button
}
```

#### App Inbox List View

The method `getAppInboxListViewController()` returns a `UIViewController` instance to display the App Inbox messages list.

The `UIViewController` implements all the data handling (fetching, displaying data, action listeners, etc.).

The default implementation builds a simple view that shows data in a `UITableView`. `UILabel` elements display empty or error state when applicable. The click action for each item in the list opens the App Inbox detail view for the `MessageItem` value.

To customize this behavior, override `getAppInboxListViewController()`. For example:

```swift
public override func getAppInboxListViewController() -> UIViewController {
   // reuse a default view or create your own
   let listController = super.getAppInboxListViewController()
   // you are able to access default class impl by casting
   let typedListController = listController as! AppInboxListViewController
   // load View to access elements
   typedListController.loadViewIfNeeded()
   // apply your setup to any element
   typedListController.statusTitle.textColor = .red
   // return instance
   return typedListController
}
```

> ❗️
>
> The methods `Exponea.shared.trackAppInboxOpened` and `Exponea.shared.markAppInboxAsRead` are called when the user clicks on an item. Please call these methods in your custom implementation to maintain correct App Inbox behavior.

#### App Inbox Detail View

The method `getAppInboxDetailViewController(String)` returns a `UIViewController` implementation to show an App Inbox message detail view.

The `UIViewController` implements all the data handling (fetching, displaying data, action listeners, etc.).

The default implementation builds a simple View that shows data by multiple `UILabel`s and a `UIImageView`. The entire layout is wrapped by a `UIScrollView`. App Inbox message actions are displayed and invoked by multiple `UIButton`s.

To customize this behavior, override `getAppInboxDetailViewController()`. For example:

```swift
public override func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
   // reuse a default view or create your own
   let detailProvider = super.getAppInboxDetailViewController(messageId)
   // you are able to access default class impl by casting
   let typedDetailProvider = detailProvider as! AppInboxDetailViewController
   // load View to access elements
   typedDetailProvider.loadViewIfNeeded()
   // apply your setup to any element
   typedDetailProvider.messageTitle.font = .systemFont(ofSize: 32)
   stylizeActionButton(typedDetailProvider.actionMain)
   stylizeActionButton(typedDetailProvider.action1)
   stylizeActionButton(typedDetailProvider.action2)
   stylizeActionButton(typedDetailProvider.action3)
   stylizeActionButton(typedDetailProvider.action4)
   // return instance
   return typedDetailProvider
}

private func stylizeActionButton(_ button: UIButton) {
   button.setTitleColor(.black, for: .normal)
   button.layer.cornerRadius = 4
   button.clipsToBounds = true
   button.backgroundColor = UIColor(red: 255/255, green: 213/255, blue: 0/255, alpha: 1.0)
}
```

> 👍
>
> **AppInbox detail image inset**
> 
> The default inset is 56 (small title, without searchBar below etc). You can set any value you want. 0 is without space between status bar and image - for transparent navigationBar for example.

> ❗️
>
> The method `Exponea.shared.trackAppInboxClick` is called when the user clicks on an action. Please call this method in your custom implementation to maintain correct App Inbox behavior.

### App Inbox Data API

The SDK provides methods to access App Inbox data directly without accessing the UI layer.

#### Fetch App Inbox

The App Inbox is assigned to an existing customer account (identified by a hard ID). Calling either of the following methods will clear the App Inbox:

- `Exponea.shared.identifyCustomer`
- `Exponea.shared.anonymize`

To prevent large data transfers on each fetch, the SDK stores the App Inbox locally and loads incrementally. The first fetch will transfer the entire App Inbox, but subsequent fetches will only transfer new messages.

The App Inbox assigned to the current customer can be fetched as follows:

```swift
Exponea.shared.fetchAppInbox { result in
   switch result {
   case .success(let messages):
      if (messages.isEmpty) {
         Exponea.logger.log(.verbose, message: "App inbox loaded but is empty")
         return
      }
      Exponea.logger.log(.verbose, message: "App inbox loaded")
   case .failure(let error):
      Exponea.logger.log(.verbose, message: "App inbox load failed due error \"\(error.localizedDescription)\"")
   }
}
```

It's also possible to fetch a single message by its ID from the App Inbox as follows:

```swift
Exponea.shared.fetchAppInboxItem(messageId) { data in
   guard let data = data else {
      Exponea.logger.log(.error, message: "AppInbox message not found for ID \(messageId)")
      return
   }
   Exponea.logger.log(.verbose, message: "AppInbox message found and loaded")
}
```

Fetching a single message triggers fetching the entire App Inbox (including incremental loading) but will retrieve the data from local storage if the App Inbox was fetched previously.

#### Mark Message as Read

Use the `markAppInboxAsRead` method to mark an App Inbox message (specified by their ID) as read:

```swift
Exponea.shared.markAppInboxAsRead(messageId) { marked in
   Exponea.logger.log(.verbose, message: "AppInbox message marked as read: \(marked)")
}
```

> ❗️
>
> Marking a message as read using the `markAppInboxAsRead` method does not trigger a tracking event for opening the message. To track an opened message, you need to call the `Exponea.shared.trackAppInboxOpened` method). 

### Track App Inbox Events Manually

The SDK tracks App Inbox events automatically by default. In case of a [custom implementation](#customize-app-inbox), it is the developers' responsibility to use the relevant tracking methods in the right places.

#### Track Opened App Inbox Message

Use the `Exponea.shared.trackAppInboxOpened(MessageItem)` method to track opening of App Inbox messages.

The behavior of `trackAppInboxOpened` may be affected by the tracking consent feature, which, when enabled, requires explicit consent for tracking. Refer to [Tracking Consent](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) for details.

If you want to ignore tracking consent, use `Exponea.shared.trackAppInboxOpenedWithoutTrackingConsent` instead. This method will track the event regardless of consent.

#### Track Clicked App Inbox Message Action

Use the `Exponea.shared.trackAppInboxClick(MessageItemAction, MessageItem)` method to track action invocations in App Inbox messages.

The behavior of `trackAppInboxClick` may be affected by the tracking consent feature, which, when enabled, requires explicit consent for tracking. Refer to [Tracking Consent](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) for details.

If you want to ignore tracking consent, use `Exponea.shared.trackAppInboxClickWithoutTrackingConsent` instead. This method will track the event regardless of consent.

### Override Button Action Type in HTML Message

The SDK automatically processes button action URLs as follows:

* If the URL starts with `http` or `https`, the action type is set to `browser`.
* In all other cases, the action type is set to `deep-link`.

It's possible to override this behavior by explicitly specifying the optional attribute `data-actiontype` with one of the following values:

* `browser` - web URL, to be opened in a browser
* `deep-link` - custom URL scheme or Universal Link, to be processed by the app accordingly

You can do this in the HTML builder by inserting the `data-actiontype` attribute as in the example below:

```html
<div class="bee-block bee-block-4 bee-button">
   <div data-link="https://example.com" data-actiontype="browser" style="font-size: 14px; background-color: #f84cac; border-bottom: 0px solid transparent; border-left: 0px solid transparent; border-radius: 4px; border-right: 0px solid transparent; border-top: 0px solid transparent; color: #ffffff; direction: ltr; font-family: inherit; font-weight: 700; max-width: 100%; padding-bottom: 4px; padding-left: 18px; padding-right: 18px; padding-top: 4px; width: auto; display: inline-block;" class="bee-button-content"><span style="word-break: break-word; font-size: 14px; line-height: 200%;">Action</span></div>
</div>
```

The SDK also supports the `data-actiontype` attribute in `<a>` elements for compatibility with the Visual builder:

```html
<div class="bee-block bee-block-4 bee-button">
   <a data-link="https://example.com" data-actiontype="deep-link">Click me</a>
</div>
```
