## In-app content blocks

Exponea SDK allows you to display native In-app content blocks based on definitions set up on the Exponea web application.

In-app content block will be shown exactly where you'll place a StaticInAppContentBlockView / prepareInAppContentBlockView. You can get a placeholder view from API:

For tableView and collectionView
```swift
    Exponea.shared.inAppContentBlockManager.prepareInAppContentBlockView(placeholderId: String, indexPath: IndexPath) -> UIView
```

You need to implement method for heightForRow
```swift
    Exponea.shared.inAppContentBlockManager.getUsedInAppContentBlocks(placeholder: "placeholder", indexPath: indexPath)?.height
```

For correct behavior you need to use in VC callback from SDK:
Animation and reload is up to you. You can reload enitre tableView or collectionView. Reload is required

```swift
    Exponea.shared.inAppContentBlockManager.refreshCallback = { [weak self] indexPath in
        onMain {
            self?.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
```

For everywhere in UIView
```swift
    StaticInAppContentBlockView(placeholder: "placeholder")
```

For correct behavior you need to use .reload() method:
 - using .reload() is fully up to you. Use it when you need to reload its content.

```swift
    let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder")
    placeholderView.reload()
``` 

In-app content blocks are shown within placeholder view by its ID automatically based on conditions setup on the Exponea backend. Once a message passes those filters, the SDK will try to present the message.

### If displaying In-app content blocks has delay

In-app content block is able to be shown only if it is fully loaded (content and height) and also its images are loaded too. In case that In-app content block is not yet fully loaded (including its images) then you may experience delayed showing.

If you need to show In-app content block as soon as possible (ideally instantly) you may set a auto-prefetch of placeholders. In-app content blocks for these placeholders are loaded immediately after SDK initialization.
For correct behavior you need to setup placeholders in config which should be downloaded: 

```swift
    Exponea.shared.inAppContentBlockManager.prefetchPlaceholdersWithIds(ids: [String])
```

This has to be done (by specification, chapter 2. Pre-fetch on SDK init) on SDK init, anonymize and identifyCustomer. Not callable anytime.

### In-app content blocks caching
To reduce the number of API calls, SDK is caching the images displayed in messages. Therefore, once the SDK downloads the image, an image with the same URL may not be downloaded again, and will not change, since it was already cached. For this reason, we recommend always using different URLs for different images.

### In-app content blocks tracking

In-app content blocks are tracked automatically by SDK. You may see these `action` values in customers tracked events:

- 'show' - event is tracked if In-app content block has been shown to user
- 'action' - event is tracked if user clicked on action button inside In-app content block. Event contains 'text' and 'link' properties that you might be interested in
- 'close' - event is tracked if user clicked on close button inside In-app content block
- 'error' - event is tracked if showing of In-app content block has failed. Event contains 'error' property with meaningfull description

You can find information on creating your messages in [Exponea documentation](https://documentation.bloomreach.com/engagement/docs/in-app-content-blocks)

> The behaviour of In-app content block tracking may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).

### Delayed In-app content blocks loading

Placing of multiple placeholders on same page may lead to unwanted performance problems. It is recommended to load In-app content block only if is visible to user, especially for large scrollable screens. You can so register an In-app content block view into layout and trigger reload later.

```swift
let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder", deferredLoad: true)
// load content later by
placeholderView.reload()
```
### Show In-app content block view after content is loaded

You may prefer UX design "finding and operating" principle so you want to show to user only available things. Or you may have a static layout where you need to set exact frame dimension to In-app content block view but it is blank until content is ready. For that case we recommend to use callback that will be notified if content has been successfully loaded or no content was found.

```swift
let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder")
placeholderView.contentReadyCompletion = { [weak self] contentLoaded in
    guard let self else { return }
    if contentLoaded {
        let contentWidth = placeholderView.frame.size.width
        let contentHeight = placeholderView.frame.size.height
        // you have exact dimensions for loaded content
    } else {
        // you can hide this view because no In-app content block is available now
        placeholderView.isHidden = true
    }
}
```

### Custom In-app content block actions

If you want to override default SDK behavior, when in-app content block action is performed (button is clicked), or you want to add your code to be performed along with code executed by the SDK, you can set up `behaviourCallback` on View instance.
Default SDK behaviour is mainly tracking of 'show', 'click', 'close' and 'error' events and opening action URL.

Customized `InAppContentBlockCallbackType` has to be registered into `StaticInAppContentBlockView` directly: 
```swift
// it is recommended to postpone message load if `onMessageShown` usage is crucial for you
// due to cached messages so message could be shown before you set `behaviourCallback`
let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder", deferredLoad: true)
// you can access original callback and invokes it anytime
let origBehaviour = placeholderView.behaviourCallback
placeholderView.behaviourCallback = CustomInAppContentBlockCallback(originalBehaviour: origBehaviour)
// `placeholderView` has deferred load, so we trigger it
placeholderView.reload()
```
Customized `behaviourCallback` has to implement `InAppContentBlockCallbackType` protocol. This example is using original/default behaviour as recommended step to use a default SDK behaviour, but it is not a required step:
```swift
class CustomInAppContentBlockCallback: InAppContentBlockCallbackType {

    private let originalBehaviour: InAppContentBlockCallbackType

    init(
        originalBehaviour: InAppContentBlockCallbackType
    ) {
        self.originalBehaviour = originalBehaviour
    }

    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        originalBehaviour.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock)
        let htmlContent = contentBlock.content?.html ?? contentBlock.personalizedMessage?.content?.html
        // you may set this placeholder visible
    }

    func onNoMessageFound(placeholderId: String) {
        originalBehaviour.onNoMessageFound(placeholderId: placeholderId)
        // you may set this placeholder hidden
    }

    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        guard let contentBlock else {
            return
        }
        // !!! invoke origBehaviour.onError to track 'error' or call it yourself
        Exponea.shared.trackInAppContentBlockError(
            placeholderId: placeholderId,
            message: contentBlock,
            errorMessage: errorMessage
        )
        // you may set this placeholder hidden and do any fallback
    }

    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // !!! invoke origBehaviour.onCloseClicked to track 'close' or call it yourself
        Exponea.shared.trackInAppContentBlockClose(
            placeholderId: placeholderId,
            message: contentBlock
        )
        // placeholder may show another content block if is assigned to placeholder ID
    }

    func onActionClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // content block action has to be tracked for 'click' event
        Exponea.shared.trackInAppContentBlockClick(
            placeholderId: placeholderId,
            action: action,
            message: contentBlock
        )
        // content block action has to be handled for given `action.url`
        handleUrlByYourApp(action.url)
    }
}
```

### Custom presentation of In-app content block

In case that UI presentation of StaticInAppContentBlockView does not fit UX design of your application (for example customized animations) you may create own UIView element that wraps existing StaticInAppContentBlockView instance.
Setup could differ from your use case but you should keep these 4 principles:

1. Prepare StaticInAppContentBlockView instance with deferred load:
```swift
class CustomView: UIViewController {

    lazy var placeholder = StaticInAppContentBlockView(placeholder: "placeholder_1", deferredLoad: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder.behaviourCallback = CustomBehaviourCallback(
            placeholder.behaviourCallback,
            placeholder,
            self
        )
        placeholderView.reload()
    }
}
```
2. Hook your CustomView to listen on In-app Content Block message arrival with customized behaviourCallback:
```swift
class CustomBehaviourCallback: InAppContentBlockCallbackType {

    private let originalBehaviour: InAppContentBlockCallbackType
    private let ownerView: StaticInAppContentBlockView
    private let viewDelegate: InAppCbViewDelegate

    init(
        _ originalBehaviour: InAppContentBlockCallbackType,
        _ ownerView: StaticInAppContentBlockView,
        _ viewDelegate: InAppCbViewDelegate
    ) {
        self.originalBehaviour = originalBehaviour
        self.ownerView = ownerView
        self.viewDelegate = viewDelegate
    }

    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // Calling originalBehavior tracks 'show' event and opens URL
        originalBehaviour.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock)
        viewDelegate.showMessage(contentBlock)
    }

    func onNoMessageFound(placeholderId: String) {
        viewDelegate.showNoMessage()
    }

    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        // Calling originalBehavior tracks 'error' event
        originalBehaviour.onError(placeholderId: placeholderId, contentBlock: contentBlock, errorMessage: errorMessage)
        viewDelegate.showError()
    }

    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // Calling originalBehavior tracks 'close' event
        originalBehaviour.onCloseClicked(placeholderId: placeholderId, contentBlock: contentBlock)
        viewDelegate.hideMe()
    }

    func onActionClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // Calling originalBehavior tracks 'click' event
        originalBehaviour.onActionClicked(placeholderId: placeholderId, contentBlock: contentBlock, action: action)
    }
}
```
3. Show retrieved message in your customized UIView:
```swift
protocol InAppCbViewDelegate {
    func showMessage(_ contentBlock: ExponeaSDK.InAppContentBlockResponse)
    func showNoMessage()
    func showError()
    func hideMe()
}

class CustomView: UIViewController, InAppCbViewDelegate {
    /// Update your customized content.
    /// This method could be called multiple times for every content block update, especially in case that multiple messages are assigned to given "placeholder_1" ID
    func showMessage(_ contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // ...
    }
}
```
4. Invoke clicked action manually. For example if your CustomView contains UIButton that is registered with `addTarget` for action URL and is calling `onMyActionClick` method:
```swift
@objc func onMyActionClick(sender: UIButton) {
    // retrieve `actionUrl` from extended UIButton or stored in some private field, it is up to you
    let actionUrl = getActionUrl(sender)
    placeholder.invokeActionClick(actionUrl: actionUrl)
}
```

That is all, now your CustomView will receive all In-app Content Block data.
