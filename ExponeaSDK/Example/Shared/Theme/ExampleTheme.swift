import SwiftUI
import UIKit

// Bloomreach brand palette.
// Yellow is a fill colour only; text, borders, cursors and focus use black or grey.
enum BrandColors {
    static let brYellow = Color(hex: 0xFFD500)
    static let brBlack = Color(hex: 0x111111)
    static let white = Color(hex: 0xFFFFFF)
    static let grey100 = Color(hex: 0xF5F5F5)
    static let grey200 = Color(hex: 0xEEEEEE)
    static let grey300 = Color(hex: 0xDDDDDD)
    static let grey400 = Color(hex: 0xBDBDBD)
    static let grey600 = Color(hex: 0x666666)
    static let grey700 = Color(hex: 0x424242)
    static let red = Color(hex: 0xD32F2F)
    static let green = Color(hex: 0x2E7D32)
    static let logVerbose = Color(hex: 0xE0E0E0)
    static let logDebug = Color(hex: 0xBBDEFB)
    static let logInfo = Color(hex: 0xC8E6C9)
    static let logWarn = Color(hex: 0xFFE082)
    static let logError = Color(hex: 0xFFCDD2)

    /// Fill of a switched-on toggle track; a fill, not a text/tint colour.
    static let switchTrack = brYellow
}

extension UIColor {
    static let brYellow = UIColor(hex: 0xFFD500)
    static let brBlack = UIColor(hex: 0x111111)

    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(UIColor(hex: hex))
    }
}

enum ExampleAppearance {
    static func configureShellNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .brBlack
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }
        navigationBar.tintColor = .white
    }

    static func configureAuthNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }
        navigationBar.tintColor = .brBlack
    }
}

struct ExampleScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandColors.grey100)
    }
}

extension View {
    func exampleScreenBackground() -> some View {
        modifier(ExampleScreenBackground())
    }

    func exampleShellNavigationBar() -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("")
                    .toolbarBackground(BrandColors.brBlack, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            } else {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("")
            }
        }
        .onAppear {
            ExampleAppearance.configureShellNavigationBar()
        }
    }

    /// Prevents scroll-edge toolbar styling on screens that use `ScrollView`.
    func exampleShellScrollContent() -> some View {
        modifier(ExampleShellScrollContent())
    }
}

private struct ExampleShellScrollContent: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .background(BrandColors.grey100)
        } else {
            content
        }
    }
}

struct ExamplePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(BrandColors.brBlack)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? BrandColors.brYellow : BrandColors.brYellow.opacity(0.5))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct ExampleOutlinedButtonStyle: ButtonStyle {
    var borderColor: Color = BrandColors.brBlack
    var foreground: Color = BrandColors.brBlack

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(foreground)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(BrandColors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct ExampleChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(BrandColors.brBlack)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? BrandColors.brYellow : BrandColors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? BrandColors.brBlack : BrandColors.grey400)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Equal-width segment control used on the Flushing tab row.
struct ExampleSegmentTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(BrandColors.brBlack)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? BrandColors.brYellow : BrandColors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? BrandColors.brYellow : BrandColors.brBlack, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct ExampleSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(BrandColors.brBlack)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(BrandColors.white)
                .shadow(color: BrandColors.brBlack.opacity(0.15), radius: 2, x: 0, y: 1)
        )
    }
}

struct ExampleStatusBox: View {
    let text: String
    var identifier: String?

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(BrandColors.grey700)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrandColors.grey200)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(BrandColors.grey300)
            )
            .modifier(OptionalAccessibilityIdentifier(identifier: identifier))
    }
}

struct OptionalAccessibilityIdentifier: ViewModifier {
    let identifier: String?

    func body(content: Content) -> some View {
        if let identifier, !identifier.isEmpty {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

struct ExamplePrimaryButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(ExamplePrimaryButtonStyle())
            .disabled(disabled)
    }
}

struct ExampleOutlinedButton: View {
    let title: String
    var borderColor: Color = BrandColors.brBlack
    var foreground: Color = BrandColors.brBlack
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(ExampleOutlinedButtonStyle(borderColor: borderColor, foreground: foreground))
            .disabled(disabled)
    }
}

struct ExampleModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(ExampleModeButtonStyle(isSelected: isSelected))
    }
}

struct ExampleModeButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(BrandColors.brBlack)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? BrandColors.brYellow : BrandColors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? BrandColors.brYellow : BrandColors.brBlack, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Bloomreach wordmark, drawn from vector paths.
struct ExampleAuthLogo: View {
    var body: some View {
        Image("BrWordmark")
            .resizable()
            .scaledToFit()
            .frame(width: 220)
            .accessibilityLabel("Bloomreach")
    }
}

/// Bloomreach mini logo, drawn from vector paths.
struct ExampleBrandMiniLogo: View {
    let size: CGFloat

    var body: some View {
        Image("BrMini")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Bloomreach")
    }
}

struct ExampleMonospacePanel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(BrandColors.grey700)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrandColors.grey200)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(BrandColors.grey300)
            )
    }
}

struct ExampleSheetHeader<Trailing: View>: View {
    let title: String
    let onClose: () -> Void
    var closeAccessibilityId: String?
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        onClose: @escaping () -> Void,
        closeAccessibilityId: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.onClose = onClose
        self.closeAccessibilityId = closeAccessibilityId
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BrandColors.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(BrandColors.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
            .modifier(OptionalAccessibilityIdentifier(identifier: closeAccessibilityId))
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(BrandColors.brBlack)
    }
}

extension ExampleSheetHeader where Trailing == EmptyView {
    init(
        title: String,
        onClose: @escaping () -> Void,
        closeAccessibilityId: String? = nil
    ) {
        self.init(title: title, onClose: onClose, closeAccessibilityId: closeAccessibilityId) {
            EmptyView()
        }
    }
}

extension View {
    @ViewBuilder
    func exampleSheetNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbarBackground(BrandColors.brBlack, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
        }
    }
}

struct ExampleShellLogoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ExampleBrandMiniLogo(size: 28)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Outlined text input style: black border (1.5pt focused),
/// 4pt corners, black cursor.
struct ExampleInputStyle: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .tint(BrandColors.brBlack)
            .foregroundColor(BrandColors.brBlack)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrandColors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(BrandColors.brBlack, lineWidth: isFocused ? 1.5 : 1)
            )
    }
}

extension View {
    func exampleInputStyle() -> some View {
        modifier(ExampleInputStyle())
    }
}
