import Foundation

enum ContentBlocksConstants {
    static let placeholderTop = "example_top"
    static let placeholderPlatform = "ph_x_example_iOS"
    static let placeholderList = "example_list"
    static let carouselDefault = "example_carousel"
    static let carouselPlatform = "example_carousel_ios"
    static let listProductCount = 50
    static let listBlockEvery = 5
    static let listHeight: CGFloat = 400

    /// Placeholders the SDK prefetches at configure (`inAppContentBlocksPlaceholders`).
    static let autoloadPlaceholders = [placeholderTop, placeholderList]
}

enum ContentBlocksTab {
    case classic
    case runtimeLab
}

@MainActor
final class ContentBlocksViewModel: ObservableObject {

    @Published var selectedTab: ContentBlocksTab = .classic
    @Published var showCarousels = false
    @Published private(set) var carouselsBuilt = false

    @Published var carouselName: String?
    @Published var carouselIndex = -1
    @Published var carouselCount = 0

    var carouselStatusText: String {
        if carouselCount == 0 {
            return "Carousel is empty"
        }
        let name = carouselName ?? ""
        return "Showing \(name) as \(carouselIndex + 1) of \(carouselCount)"
    }

    func setShowCarousels(_ value: Bool) {
        showCarousels = value
        if value {
            carouselsBuilt = true
        }
    }

    func updateCarouselShown(name: String?, index: Int, count: Int) {
        carouselName = name
        carouselIndex = index
        carouselCount = count
    }

    func updateCarouselMessageCount(_ count: Int) {
        carouselCount = count
        if count == 0 {
            carouselName = nil
            carouselIndex = -1
        }
    }
}
