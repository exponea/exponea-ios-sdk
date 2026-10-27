import ExponeaSDK
import UIKit

final class ExampleFilteredCarouselView: CarouselInAppContentBlockView {
    override func filterContentBlocks(
        placeholder: String,
        continueCallback: TypeBlock<[InAppContentBlockResponse]>?,
        expiredCompletion: EmptyBlock?
    ) {
        super.filterContentBlocks(placeholder: placeholder) { data in
            let filtered = data.filter { !$0.name.localizedCaseInsensitiveContains("discarded") }
            continueCallback?(filtered)
        } expiredCompletion: {
            expiredCompletion?()
        }
    }

    override func sortContentBlocks(data: [StaticReturnData]) -> [StaticReturnData] {
        super.sortContentBlocks(data: data).reversed()
    }
}

final class ExampleCarouselStatusCallback: DefaultContentBlockCarouselCallback {
    var overrideDefaultBehavior = false
    var trackActions = true

    private let onShown: (String, Int, Int) -> Void
    private let onChanged: (Int) -> Void

    init(
        onShown: @escaping (String, Int, Int) -> Void,
        onChanged: @escaping (Int) -> Void
    ) {
        self.onShown = onShown
        self.onChanged = onChanged
    }

    func onMessageShown(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        index: Int,
        count: Int
    ) {
        onShown(contentBlock.name, index, count)
    }

    func onMessagesChanged(count: Int, messages: [InAppContentBlockResponse]) {
        onChanged(count)
    }

    func onNoMessageFound(placeholderId: String) {
        onChanged(0)
    }

    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String) {}
    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse) {}
    func onActionClickedSafari(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction
    ) {}
    func onHeightUpdate(placeholderId: String, height: CGFloat) {}
}
