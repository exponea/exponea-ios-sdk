import UIKit
import CoreText

/// Shares registration handling between downloaded fonts and cached message payloads.
enum InAppFontLoader {
    private static let lock = NSLock()

    static func load(base64: String?, size: CGFloat?) -> UIFont? {
        guard let base64 = base64,
              let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return load(data: data, size: size)
    }

    static func load(data: Data, size: CGFloat?) -> UIFont? {
        guard let provider = CGDataProvider(data: data as CFData),
              let graphicsFont = CGFont(provider),
              let name = graphicsFont.postScriptName as String? else {
            Exponea.logger.log(.error, message: "[InApp] Invalid custom font data")
            return nil
        }

        // Keep SDK registration and cleanup together when messages load concurrently.
        lock.lock()
        defer { lock.unlock() }
        var registrationError: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterGraphicsFont(graphicsFont, &registrationError)
        let error = registrationError?.takeRetainedValue()
        defer {
            // A bundled font belongs to the host app; never unregister it.
            if registered {
                CTFontManagerUnregisterGraphicsFont(graphicsFont, nil)
            }
        }

        if !registered {
            guard let error = error,
                  CFErrorGetDomain(error) == kCTFontManagerErrorDomain,
                  CFErrorGetCode(error) == CTFontManagerError.alreadyRegistered.rawValue ||
                    CFErrorGetCode(error) == CTFontManagerError.duplicatedName.rawValue else {
                Exponea.logger.log(
                    .error,
                    message: "[InApp] Cannot register custom font \(name): \(error.map { "\($0)" } ?? "unknown error")"
                )
                return nil
            }
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Custom font \(name) is already registered by the app, using the registered font"
            )
        }
        guard let font = UIFont(name: name, size: size ?? 13) else {
            Exponea.logger.log(.error, message: "[InApp] Cannot resolve custom font \(name)")
            return nil
        }
        return font
    }
}
