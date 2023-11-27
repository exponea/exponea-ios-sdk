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
