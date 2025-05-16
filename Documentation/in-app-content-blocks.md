---
title: In-app content blocks
excerpt: Display native in-app content blocks based on definitions set up in Engagement using the iOS SDK
slug: ios-sdk-in-app-content-blocks
categorySlug: integrations
parentDocSlug: ios-sdk-in-app-personalization
---

In-app content blocks provide a way to display campaigns within your mobile applications that seamlessly blend with the overall app design. Unlike [in-app messages](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-messages) that appear as overlays or pop-ups demanding immediate attention, in-app content blocks display inline with the app's existing content.

You can strategically position placeholders for in-app content blocks within your app. You can customize the behavior and presentation to meet your specific requirements.

> 📘
>
> Refer to the [In-app content blocks](https://documentation.bloomreach.com/engagement/docs/in-app-content-blocks) user guide for instructions on how to create in-app content blocks in Engagement.

![In-app content blocks in the example app](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/in-app-content-blocks.png)

## Integration of a placeholder view

You can integrate in-app content blocks by adding one or more placeholder views in your app. Each in-app content block must have a `Placeholder ID` specified in its [settings](https://documentation.bloomreach.com/engagement/docs/in-app-content-blocks#3-fill-the-settings) in Engagement. The SDK will display an in-app content block in the corresponding placeholder in the app if the current app user matches the target audience.

### In a generic view

In a generic [view](https://developer.apple.com/documentation/uikit/uiview), initialize a `StaticInAppContentBlockView` to the view controller with its `placeholderId`:

```swift
lazy var placeholder = StaticInAppContentBlockView(placeholder: "example_content_block")
```

Then, place the placeholder view at the desired location by adding it as a sub view to a parent view:
```swift
view.addSubview(placeholder)
```

Use the `.reload()` method if you need to reload the content block view:

```swift
placeholder.reload()
```

### In a table view or collection view

In a [table view](https://developer.apple.com/documentation/uikit/uitableview/) or [collection view](https://developer.apple.com/documentation/uikit/uicollectionview/), use the `prepareInAppContentBlockView` method, specifying the content block's `placeholderID` and the `indexPath` of the table row or collection item where you want to add the in-app content block.

```swift
Exponea.shared.inAppContentBlocksManager?.prepareInAppContentBlockView(placeholderId: "example_content_block", indexPath: 5)
```

Use the SDK's `refreshCallback` to reload your entire table view or collection view when needed:

```swift
Exponea.shared.inAppContentBlocksManager?.refreshCallback = { [weak self] indexPath in
    onMain {
        self?.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
    }
}
```


> 📘
>
> Refer to [InAppContentBlocksViewController](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlocksViewController.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a reference implementation.

> 👍
>
> Always us descriptive, human-readable placeholder IDs. They are tracked as an event property and can be used for analytics within Engagement.

## Integration of a carousel view

If you want to show multiple in-app content blocks to the user for the same `Placeholder ID`, consider using `CarouselInAppContentBlockView`. The SDK will display the in-app content blocks for the current app user in a loop, in order of `Priority`. The in-app content blocks are displayed in a loop until the user interacts with them or until the carousel view instance is reloaded programmatically.

If the carousel view's placeholder ID only matches a single in-app content block, it will behave like a static placeholder view with no loop effect.

### Add a carousel view

Get a carousel view for the specified `placeholderId` with default configuration:

```swift
 let carouselView = CarouselInAppContentBlockView(placeholder: "placeholderId")
```

Optionally, you can configure the carousel view's maximum number of messages to display, custom height, and scroll delay to fit your requirements:

```swift
 let carouselView = CarouselInAppContentBlockView(
        placeholder: "placeholderId",
        maxMessagesCount: 5, // max count of visible content blocks; 0 for show all; default value is 0
        customHeight: 200, // nil for autoheight; default value is nil
        scrollDelay: 5 // delay in seconds between automatic scroll; 0 for no scroll; default value is 3
    )
```

Then, place the placeholder view at the desired location by adding it to your layout:

```swift
view.addSubview(carouselView)
```

Finally, call the following methods in the following places for correct behavior:

Inside `viewDidLoad()`/`loadView()` in your view controller:
```swift
carouselView.reload()
```

Inside `deinit`:
```swift
carouselView.release()
```

Inside `viewWillAppear`:
```swift
carouselView.continueWithTimer()
```

## Tracking

The SDK automatically tracks `banner` events for in-app content blocks with the following values for the `action` event property:

- `show`
  In-app content block displayed to user.
- `action`
  User clicked on action button inside in-app content block. The event also contains the corresponding `text` and `link` properties.
- `close`
  User clicked on close button inside in-app content block.
- `error`
  Displaying in-app content block failed. The event contains an `error` property with an error message.

> ❗️
>
> The behavior of in-app content block tracking may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [consent documentation](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation for details.

## Customization

### Prefetch in-app content blocks

The SDK can only display an in-app content block after it has been fully loaded (including its content, any images, and its height). Therefore, the in-app content block may only show in the app after a delay.

You may prefetch in-app content blocks for specific placeholders to make them display as soon as possible.

```swift
Exponea.shared.inAppContentBlocksManager?.prefetchPlaceholdersWithIds(ids: ["placeholder_1", "placeholder_2"])
```

This must be done after SDK [initialization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk) and after calling `anonymize` or `identifyCustomer`. Prefetching should not be done at any other time.

### Handle carousel presentation status

If you need to access additional information about content blocks displayed in a carousel, you can use the following methods:

```swift
// returns complete InAppContentBlock structure of shown content block or null
let blockName = carouselView.getShownContentBlock()?.message?.name
// returns zero-base index of shown content block or -1 for empty list
let index = carouselView.getShownIndex()
// returns count of content blocks available for user
let count = carouselView.getShownCount()
```

You can register a `onMessageShown` or `onMessageChanged` callback to a carousel view instance to retrieve information for each update.

```swift
// This is triggered on each scroll so 'contentBlock' parameter represents currently shown content block
carouselView.onMessageShown = { message in
    print(message.index) // so as 'index' represents position index of currently shown content block 
    print(message.placeholderId)
}

// This is triggered after 'reload' or if a content block is removed because interaction has been done
carouselView.onMessageChanged = { data in
    print("ON MESSAGE CHANGED")
    print(data)
}    
```

### Defer in-app content blocks loading

Placing multiple placeholders on the same screen may have a negative impact on performance. We recommend only loading in-app content blocks that are visible to the user, especially for large scrollable screens.

To add a placeholder to your layout but defer loading of the corresponding in-app content block, enable `deferredLoad` on the `StaticInAppContentBlockView` instance:

```swift
let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder", deferredLoad: true)
```

Then call `reload()` later when the placeholder becomes visible to the user:
```swift
placeholderView.reload()
```

### Display in-app content block after content has loaded

You may want to render your app's UI differently depending on whether an in-app content block is available. For example, your layout may depend on the exact dimensions of the in-app content block, which are only known once it has been loaded.

In such use cases you can use the `contentReadyCompletion` on the placeholder view to get notified when an in-app content block has been successfully loaded or no content was found.

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

In such use cases you can use the `calculator.publicHeightUpdate` callback on the placeholder view to get notified when an in-app content block changed its height.

```swift
lazy var placeholder = StaticInAppContentBlockView(placeholder: "example_top", deferredLoad: true)
placeholder.calculator.publicHeightUpdate = { calculator in
    print(calculator.height)
}
```

### Customize action behavior

When an in-app content block action (show, click, close, error) is performed, by default, the SDK tracks the appropriate event and, in case of a button click, opens a link. It's possible to customize this behavior.

#### Static view

You can override or customize the default action behavior by setting `behaviourCallback` on the `StaticInAppContentBlockView`.

```swift
// it is recommended to postpone message load if `onMessageShown` usage is crucial for you
// due to cached messages so message could be shown before you set `behaviourCallback`
let placeholderView = StaticInAppContentBlockView(placeholder: "placeholder", deferredLoad: true)

// you can access original callback and invokes it anytime
let originalBehaviour = placeholderView.behaviourCallback
placeholderView.behaviourCallback = CustomInAppContentBlockCallback(originalBehaviour: originalBehaviour)

// `placeholderView` has deferred load, so we trigger it
placeholderView.reload()
```

The callback behavior object must implement `InAppContentBlockCallbackType`. The example below calls the original (default) behavior. This is recommended but not required.

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

> 📘
>
> Refer to [InAppContentBlocksViewController](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlocksViewController.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a working example.

#### Carousel view

You can configure the action behavior for a `CarouselInAppContentBlockView` through `contentBlockCarouselCallback` by setting the `trackActions` and `overrideDefaultBehavior` flags.

##### trackActions

- Default value: `true`
- If `false`, events "close" and "click" on banners won't be tracked by the SDK. You can add your custom behavior via `customContentBlockCarouselCallback` (see example [below](#customcontentblockcarouselcallback)).

```swift
carousel.contentBlockCarouselCallback.trackActions = false
```

##### overrideDefaultBehavior

- Default value: `false`
- If `true`, deep links and universal links won't be opened. You can add your custom behavior via `customContentBlockCarouselCallback` (see example [below](#customcontentblockcarouselcallback)).

##### customContentBlockCarouselCallback

You can add your custom behavior by setting `customContentBlockCarouselCallback` on the `CarouselInAppContentBlockView`:

```swift
CarouselInAppContentBlockView(placeholder: "example_carousel", customContentBlockCarouselCallback: CustomCarouselCallback())
```

The callback behavior object must implement `DefaultContentBlockCarouselCallback`.

```swift
public class CustomCarouselCallback: DefaultContentBlockCarouselCallback {

    public var overrideDefaultBehavior: Bool = false
    public var trackActions: Bool = true

    public func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    public func onNoMessageFound(placeholderId: String) {
        // space for custom implementation
    }

    public func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        // space for custom implementation
    }

    public func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    public func onActionClickedSafari(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // space for custom implementation
    }

    public func onHeightUpdate(placeholderId: String, height: CGFloat) {
        // Triggered when a carousel changed its height.
    }
}
```

### Override button action type in HTML message

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

In the Visual builder, you can set the action type as follows:

1) In the preview, select the button you want to override the action type for
2) In the editor on the right side, scroll down to the `Attributes` section
3) Click on `ADD NEW ATTRIBUTE`
4) Select `data-actiontype`
5) Insert a value (either `browser` or  `deep-link`)

![Screenshot](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/actiontype.png)

### Customize presentation

If the default UI presentation of the `StaticInAppContentBlockView` doesn't fit the UX design of your app, you can create a `UIView` element that wraps the existing `StaticInAppContentBlockView` instance.

The exact implementation will depend on your use case but should, in general, have the following four elements:

1. Prepare a `StaticInAppContentBlockView` instance with deferred loading enabled, and set `behaviourCallback` (you will implement the behavior in the next step):
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
2. Implement `InAppContentBlockCallbackType` with the desired behavior:
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
3. Implement a view delegate in your custom view to display the in-app content block:
```swift
protocol InAppCbViewDelegate {
    func showMessage(_ contentBlock: ExponeaSDK.InAppContentBlockResponse)
    func showNoMessage()
    func showError()
    func hideMe()
}

class CustomView: UIViewController, InAppCbViewDelegate {
    /// Update your customized content.
    /// This method could be called multiple times for every content block update, especially in case multiple messages are assigned to given "placeholder_1" ID
    func showMessage(_ contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // ...
    }
}
```
4. Call `invokeActionClick` on the placeholder manually. For example, if `CustomView` contains a `UIButton` that is registered with `addTarget` for action URL and is calling the `onMyActionClick` method:
```swift
@objc func onMyActionClick(sender: UIButton) {
    // retrieve `actionUrl` from extended UIButton or stored in some private field, it is up to you
    let actionUrl = getActionUrl(sender)
    placeholder.invokeActionClick(actionUrl: actionUrl)
}
```
### Customize carousel view filtration and sorting

A carousel view filters available content blocks in the same way as a placeholder view:

- The content block must meet the `Display` setting configured in the Engagement web app
- The content must be valid and supported by the SDK

The order in which content blocks are displayed is determined by:

1. By the `Priority` setting, descending
2. By the `Name`, ascending (alphabetically)

You can extend `CarouselInAppContentBlockView` to override methods like `func filterContentBlocks(placeholder: String, continueCallback: TypeBlock<[InAppContentBlockResponse]>?, expiredCompletion: EmptyBlock?)` and `func sortContentBlocks(data: [StaticReturnData]) -> [StaticReturnData]`. Refer to [`InAppContentBlockCarouselViewController`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlockCarouselViewController.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for an example implementation ()`CustomCarouselView`).

```swift
class CustomCarouselView: CarouselInAppContentBlockView {
    override func filterContentBlocks(placeholder: String, continueCallback: TypeBlock<[InAppContentBlockResponse]>?, expiredCompletion: EmptyBlock?) {
        super.filterContentBlocks(placeholder: placeholder) { data in
            let customFilter = data.filter { !$0.name.contains("test") } // custom filter
            continueCallback?(customFilter) // data passed through this callback will be applied
        } expiredCompletion: {
            expiredCompletion?() // If you want to log expired messages or something, you can put it to this place
        }
    }

    override func sortContentBlocks(data: [StaticReturnData]) -> [StaticReturnData] {
        let origin = super.sortContentBlocks(data: data) // our filter + your update
        return origin.sorted(by: { $0.tag < $1.tag })
        
        ========= OR =========
        
        return data.sorted(by: { $0.tag < $1.tag }) // just your filter update
    }
}
```

> ❗️
>
> A carousel view accepts the results from the filtration and sorting implementations. Ensure that you return all wanted items as result from your implementations to avoid any missing items.

> ❗️
>
> A carousel view can be configured with `maxMessagesCount`. Any value higher than zero applies a maximum number of content blocks displayed, independently of the number of results from filtration and sorting methods. So if you return 10 items from filtration and sorting method but `maxMessagesCount` is set to 5 then only first 5 items from your results.


## Troubleshooting

This section provides helpful pointers for troubleshooting in-app content blocks issues.

> 👍 Enable Verbose Logging
> The SDK logs a lot of information in verbose mode while loading in-app content blocks. When troubleshooting in-app content block issues, first ensure to [set the SDK's log level](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#log-level) to `.verbose`.

### In-app content block not displayed

- The SDK can only display an in-app content block after it has been fully loaded (including its content, any images, and its height). Therefore, the in-app content block may only show in the app after a delay.
- Always ensure that the placeholder IDs in the in-app content block configuration (in the Engagement web app) and in your mobile app match.

### In-app content block shows incorrect image

- To reduce the number of API calls and fetching time of in-app content blocks, the SDK caches the images contained in content blocks. Once the SDK downloads an image, an image with the same URL may not be downloaded again. If a content block contains a new image with the same URL as a previously used image, the previous image is displayed since it was already cached. For this reason, we recommend always using different URLs for different images.

### Log messages

While troubleshooting in-app content block issues, you can find useful information in the messages logged by the SDK at verbose log level. Look for messages similar to the ones below:

1. ```
    InAppCB: Placeholder ["placeholder"] has invalid state - action or message is invalid.
    ```
    Data for the message is nil. Try to call `.reload()` method over static CB.

2. ```
    InAppCB: Unknown action URL: ["url"]
    ```
    Invalid action URL. Verify the URL for the content block in the Engagement web app.
3. ```
    InAppCB: Manual action ["actionUrl"] invoked on placeholder ["placeholder"]
    ```
    This log message informs you which action/URL was called.
4.  ```
    WebActionManager error ["error"] and [HTML] Action URL ["url"] cannot be found as action
    ```
    Invalid URL or action can't be found. Check for a typo in the action name.
5. ```
    [HTML] Unknown action URL: ["url"]
    ```
    Invalid action - verify that the name is correct.
6. ```
    [HTML] Action ["url"] has been handled
    ```
    Everything is set up correctly.
    
