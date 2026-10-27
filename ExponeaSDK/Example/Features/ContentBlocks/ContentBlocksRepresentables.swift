import SwiftUI
import UIKit
import ExponeaSDK

struct DefaultCarouselContentBlockRepresentable: UIViewRepresentable {

    @ObservedObject var viewModel: ContentBlocksViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> CarouselInAppContentBlockView {
        let carousel = CarouselInAppContentBlockView(
            placeholder: ContentBlocksConstants.carouselDefault,
            behaviourCallback: context.coordinator.callback
        )
        context.coordinator.carousel = carousel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            carousel.reload()
        }
        return carousel
    }

    func updateUIView(_ uiView: CarouselInAppContentBlockView, context: Context) {}

    static func dismantleUIView(_ uiView: CarouselInAppContentBlockView, coordinator: Coordinator) {
        uiView.release()
    }

    final class Coordinator {
        let callback: ExampleCarouselStatusCallback
        weak var carousel: CarouselInAppContentBlockView?

        init(viewModel: ContentBlocksViewModel) {
            callback = ExampleCarouselStatusCallback(
                onShown: { name, index, count in
                    Task { @MainActor in
                        viewModel.updateCarouselShown(name: name, index: index, count: count)
                    }
                },
                onChanged: { count in
                    Task { @MainActor in
                        viewModel.updateCarouselMessageCount(count)
                    }
                }
            )
        }
    }
}

struct FilteredCarouselContentBlockRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ExampleFilteredCarouselView {
        let carousel = ExampleFilteredCarouselView(
            placeholder: ContentBlocksConstants.carouselDefault,
            maxMessagesCount: 5,
            scrollDelay: 10
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            carousel.reload()
        }
        return carousel
    }

    func updateUIView(_ uiView: ExampleFilteredCarouselView, context: Context) {}

    static func dismantleUIView(_ uiView: ExampleFilteredCarouselView, coordinator: ()) {
        uiView.release()
    }
}

struct PlatformCarouselContentBlockRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> CarouselInAppContentBlockView {
        let carousel = CarouselInAppContentBlockView(
            placeholder: ContentBlocksConstants.carouselPlatform,
            scrollDelay: 1000
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            carousel.reload()
        }
        return carousel
    }

    func updateUIView(_ uiView: CarouselInAppContentBlockView, context: Context) {}

    static func dismantleUIView(_ uiView: CarouselInAppContentBlockView, coordinator: ()) {
        uiView.release()
    }
}

/// Product list with an `example_list` content block every Nth row. Each block is its own
/// `StaticInAppContentBlockView`.
struct InlineContentBlockList: View {

    private let productCount = ContentBlocksConstants.listProductCount
    private let blockEvery = ContentBlocksConstants.listBlockEvery

    private var itemCount: Int {
        productCount + productCount / blockEvery
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<itemCount, id: \.self) { position in
                    if position.isMultiple(of: blockEvery) {
                        ContentBlockPlaceholderView(
                            placeholderId: ContentBlocksConstants.placeholderList
                        )
                    } else {
                        productRow(number: productDataIndex(for: position) + 1)
                        Divider()
                    }
                }
            }
        }
    }

    private func productRow(number: Int) -> some View {
        HStack(spacing: 16) {
            Image(systemName: Self.productIcons[(number - 1) % Self.productIcons.count])
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Product \(number)")
                    .font(.body)
                Text("Demo description for product \(number).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private static let productIcons = [
        "bag",
        "square.and.pencil",
        "icloud.and.arrow.down",
        "rectangle.on.rectangle"
    ]

    /// Ceiling division keeps product numbering continuous across content block rows;
    /// integer division would skip Product 1.
    private func productDataIndex(for position: Int) -> Int {
        position - Int((Double(position) / Double(blockEvery)).rounded(.up))
    }
}
