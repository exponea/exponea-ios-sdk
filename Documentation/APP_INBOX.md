## App Inbox

Exponea SDK feature App Inbox allows you to use message list in your app. You can find information on creating your messages in [Exponea documentation](https://documentation.bloomreach.com/engagement/docs/app-inbox).

### Using App Inbox

Only required step to use App Inbox in your application is to add a button into your screen. Messages are then displayed by clicking on a button:

```swift
override func viewDidLoad() {
   super.viewDidLoad()
   let button = Exponea.shared.getAppInboxButton()
   self.buttonsStack.addArrangedSubview(button)
   let widthConstraint = button.widthAnchor.constraint(equalToConstant: 48)
   let heightConstraint = button.heightAnchor.constraint(equalToConstant: 48)
   NSLayoutConstraint.activate([widthConstraint, heightConstraint])
}
```

App Inbox button has registered a click action to show an App Inbox list screen.

> Always check for retrieved button instance nullability. Button cannot be build for non-initialized Exponea SDK.

No more work is required for showing App Inbox but may be customized in multiple ways.

## Default App Inbox behavior

Exponea SDK is fetching and showing an App Inbox for you automatically in default steps:

1. Shows a button to access App Inbox list (need to be done by developer)
2. Shows a screen for App Inbox list. Each item is shown with:
   1. Flag if message is read or unread
   2. Delivery time in human-readable form (i.e. `2 hours ago`)
   3. Single-lined title of message ended by '...' for longer value 
   4. Two-lined content of message ended by '...' for longer value
   5. Squared image if message contains any
   6. Shows a loading state of list (indeterminate progress)
   7. Shows an empty state of list with title and message
   8. Shows an error state of list with title and description
3. Screen for App Inbox list calls a `Exponea.shared.trackAppInboxOpened` on item click and marks message as read automatically
4. Shows a screen for App Inbox message detail that contains:
   1. Large squared image. A gray placeholder is shown if message has no image
   2. Delivery time in human-readable form (i.e. `2 hours ago`)
   3. Full title of message
   4. Full content of message
   5. Buttons for each reasonable action (actions to open browser link or invoking of universal link). Action that just opens current app is meaningless so is not listed
5. Screen for message detail calls `Exponea.shared.trackAppInboxClick` on action button click automatically

> The behavior of `trackAppInboxOpened` and `trackAppInboxClick` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).

### Localization

Exponea SDK contains only texts in EN translation. To modify this or add a localization, you are able to define customized strings (i.e. in your `Localizable.string` files)

```text
"exponea.inbox.button" = "Inbox";
"exponea.inbox.title" = "AppInbox";
"exponea.inbox.loading" = "Loading messages...";
"exponea.inbox.emptyTitle" = "Empty Inbox";
"exponea.inbox.emptyMessage" = "You have no messages yet.";
"exponea.inbox.errorTitle" = "Something went wrong :(";
"exponea.inbox.errorMessage" = "We could not retrieve your messages.";
"exponea.inbox.defaultTitle" = "Message";
"exponea.inbox.mainActionTitle" = "See more";
```

### UI components styling

If you want to override UI elements, you are able to register your own `AppInboxProvider` implementation:

```swift
Exponea.shared.appInboxProvider = ExampleAppInboxProvider()
```

> You may register your own provider at any time - before Exponea SDK init or later in some of your screens. Every action in scope of App Inbox is using currently registered provider instance. Nevertheless, we recommend to set your provider right after Exponea SDK initialization.

`AppInboxProvider` instance must contain implementation for building of all UI components, but you are allowed to extend from SDKs `DefaultAppInboxProvider` and re-implement only UI views that you need to.

### Building App Inbox button

Method `getAppInboxButton()` is used to build a `UIButton` instance.
Default implementation builds a simple button instance with icon ![INBOX](./inbox.png) and `exponea.inbox.button` text.
Click action for that button is set to open App Inbox list screen.
To override this behavior you are able to write own method:

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

### Building App Inbox list controller

Method `getAppInboxListViewController()` is used to build a `UIViewController` to show a App Inbox list. All data handling has to be done in UIViewController implementation (fetching, showing data, onItemClicked listeners...).
Default implementation builds a simple screen that shows data in `UITableView`, empty or error state is shown by other `UILabel` elements.
On-item-clicked action for each item is set to open App Inbox detail screen for `MessageItem` value.
To override this behavior you are able to write own method:

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

> Event tracking `Exponea.shared.trackAppInboxOpened` and message read state `Exponea.shared.markAppInboxAsRead` are called by clicking on item. Please call these methods in your customized implementation to keep a proper App Inbox behavior.

### Building App Inbox detail View

Method `getAppInboxDetailViewController(String)` is used to build a `UIViewController` to show an App Inbox message detail. All data handling has to be done UIViewController implementation (fetching, showing data, action listeners...).
Default implementation builds a simple View that shows data by multiple `UILabel`s and `UIImageView`, whole layout wrapped by `UIScrollView`.
App Inbox message actions are shown and invoked by multiple `UIButton`s.
To override this behavior you are able to write own method:

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

> Event tracking `Exponea.shared.trackAppInboxClick` is called by clicking on action. Please call these methods in your customized implementation to keep a proper App Inbox behavior.

## App Inbox data API

Exponea SDK provides methods to access App Inbox data directly without accessing UI layer at all.

### App Inbox load

App Inbox is assigned to existing customer account (defined by hardIds) so App Inbox is cleared in case of: 

- calling any `Exponea.shared.identifyCustomer` method
- calling any `Exponea.shared.anonymize` method

To prevent a large data transferring on each fetch, App Inbox is stored locally and next loading is incremental. It means that first fetch contains whole App Inbox but next requests contain only new messages. You are freed by handling such a behavior, result data contains whole App Inbox but HTTP request in your logs may be empty for that call.
List of assigned App Inbox is done by

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

Exponea SDK provides API to get single message from App Inbox. To load it you need to pass a message ID:

```swift
Exponea.shared.fetchAppInboxItem(messageId) { data in
   guard let data = data else {
      Exponea.logger.log(.error, message: "AppInbox message not found for ID \(messageId)")
      return
   }
   Exponea.logger.log(.verbose, message: "AppInbox message found and loaded")
}
```
Fetching of single message is still requesting for fetch of App Inbox (including incremental loading). But message data are returned from local repository in normal case (due to previous fetch of App Inbox).

### App Inbox message read state

To set an App Inbox message read flag you need to pass a message ID:
```swift
Exponea.shared.markAppInboxAsRead(messageId) { marked in
   Exponea.logger.log(.verbose, message: "AppInbox message marked as read: \(marked)")
}
```
> Marking a message as read by `markAppInboxAsRead` method is not invoking a tracking event for opening a message. To track an opened message, you need to call `Exponea.shared.trackAppInboxOpened` method. 

## Tracking events for App Inbox

Exponea SDK default behavior is tracking the events for you automatically. In case of your custom implementation, please use tracking methods in right places.

### Tracking opened App Inbox message

To track an opening of message detail, you should use method `Exponea.shared.trackAppInboxOpened(MessageItem)` with opened message data.
The behaviour of `trackAppInboxOpened` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).
If you want to avoid to consider tracking, you may use `Exponea.shared.trackAppInboxOpenedWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Tracking clicked App Inbox message action

To track an invoking of action, you should use method `Exponea.shared.trackAppInboxClick(MessageItemAction, MessageItem)` with clicked message action and data.
The behaviour of `trackAppInboxClick` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).
If you want to avoid to consider tracking, you may use `Exponea.shared.trackAppInboxClickWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.
