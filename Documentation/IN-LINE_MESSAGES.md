## Inline messages
Exponea SDK allows you to display native Inline messages based on definitions set up on the Exponea web application. You can find information on creating your messages in [Exponea documentation](TBD).

Inline message will be shown exactly where you'll place a Inline placeholder UI view. You can get a placeholder view from API:

For tableView and collectionView
```swift
    func prepareInlineView(placeholderId: "placeholder", indexPath: IndexPath) -> UIView
```

You need to implement method for heightForRow
```swift
    InlineMessageManager.manager.getUsedInline(placeholder: "placeholder", indexPath: indexPath)?.height
```

For correct behavior you need to use in VC callback from SDK:
Animation and reload is up to you. You can reload enitre tableView or collectionView. Reload is required

```swift
    InlineMessageManager.manager.refreshCallback = { [weak self] indexPath in
        onMain {
            self?.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
```

For everywhere in UIView
```swift
    StaticInlineView(placeholder: "placeholder")
```

For correct behavior you need to use .reload() method:

```swift
    let placeholderView = StaticInlineView(placeholder: "placeholder")
    placeholderView.reload()
``` 

Inline messages are shown within placeholder view by its ID automatically based on conditions setup on the Exponea backend. Once a message passes those filters, the SDK will try to present the message.

### If displaying Inline messages has delay

Message is able to be shown only if it is fully loaded (content and height) and also its images are loaded too. In case that message is not yet fully loaded (including its images) then you may experience delayed showing.

If you need to show Inline message as soon as possible (ideally instantly) you may set a auto-prefetch of placeholders. Inline messages for these placeholders are loaded immediately after SDK initialization.

```swift
    InlineMessageManager.manager.prefetchPlaceholdersWithIds(ids: [String])
```

### Inline images caching
To reduce the number of API calls, SDK is caching the images displayed in messages. Therefore, once the SDK downloads the image, an image with the same URL may not be downloaded again, and will not change, since it was already cached. For this reason, we recommend always using different URLs for different images.

### Inline messages tracking

Inline messages are tracked automatically by SDK. You may see these `action` values in customers tracked events:

- 'show' - event is tracked if message has been shown to user
- 'action' - event is tracked if user clicked on action button inside message. Event contains 'text' and 'link' properties that you might be interested in
- 'close' - event is tracked if user clicked on close button inside message
- 'error' - event is tracked if showing of message has failed. Event contains 'error' property with meaningfull description

> The behaviour of Inline message tracking may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).
