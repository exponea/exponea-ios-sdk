//
//  StyleExtensions.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue, alpha: UInt64
        switch hex.count {
        case 3: // #rgb (12-bit)
            (red, green, blue, alpha) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 4: // #rgba (16bit)
            (red, green, blue, alpha) = ((int >> 16) * 17, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // #rrggbb (24-bit)
            (red, green, blue, alpha) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // #rrggbbaa (32-bit)
            (red, green, blue, alpha) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
    convenience init?(rgbaString: String) {
        // rgba(255, 255, 255, 1.0)
        // rgba(255 255 255 / 1.0)
        do {
            let rgbaFormat = try NSRegularExpression(
                pattern: "^rgba\\([ ]*([0-9]{1,3})[, ]+([0-9]{1,3})[, ]+([0-9]{1,3})[,/ ]+([0-9.]+)[ ]*\\)$",
                options: .caseInsensitive
            )
            let rgbaValues = rgbaFormat.matches(
                in: rgbaString,
                range: NSRange(location: 0, length: rgbaString.utf16.count)
            )
            guard let rgbaResult = rgbaValues.first,
                  let rRange = Range(rgbaResult.range(at: 1), in: rgbaString),
                  let gRange = Range(rgbaResult.range(at: 2), in: rgbaString),
                  let bRange = Range(rgbaResult.range(at: 3), in: rgbaString),
                  let aRange = Range(rgbaResult.range(at: 4), in: rgbaString),
                  let red = CGFloat.parse(String(rgbaString[rRange])),
                  let green = CGFloat.parse(String(rgbaString[gRange])),
                  let blue = CGFloat.parse(String(rgbaString[bRange])),
                  let alpha = CGFloat.parse(String(rgbaString[aRange])) else {
                ExponeaSDK.Exponea.logger.log(.warning, message: "Unable to parse RGBA color \(rgbaString)")
                return nil
            }
            self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
        } catch let error {
            ExponeaSDK.Exponea.logger.log(
                .warning,
                message: "Unable to parse RGBA color \(rgbaString): \(error.localizedDescription)"
            )
            return nil
        }
    }
    convenience init?(rgbString: String) {
        // rgb(255, 255, 255)
        do {
            let rgbFormat = try NSRegularExpression(
                pattern: "^rgb\\([ ]*([0-9]{1,3})[, ]+([0-9]{1,3})[, ]+([0-9]{1,3})[ ]*\\)$",
                options: .caseInsensitive
            )
            let rgbValues = rgbFormat.matches(
                in: rgbString,
                range: NSRange(location: 0, length: rgbString.utf16.count)
            )
            guard let rgbResult = rgbValues.first,
                  let rRange = Range(rgbResult.range(at: 1), in: rgbString),
                  let gRange = Range(rgbResult.range(at: 2), in: rgbString),
                  let bRange = Range(rgbResult.range(at: 3), in: rgbString),
                  let red = CGFloat.parse(String(rgbString[rRange])),
                  let green = CGFloat.parse(String(rgbString[gRange])),
                  let blue = CGFloat.parse(String(rgbString[bRange])) else {
                ExponeaSDK.Exponea.logger.log(.warning, message: "Unable to parse RGB color \(rgbString)")
                return nil
            }
            self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1.0)
        } catch let error {
            ExponeaSDK.Exponea.logger.log(
                .warning,
                message: "Unable to parse RGB color \(rgbString): \(error.localizedDescription)"
            )
            return nil
        }
    }
    convenience init?(argbString: String) {
        // argb(1.0, 255, 0, 0)
        do {
            let argbFormat = try NSRegularExpression(
                pattern: "^argb\\([ ]*([0-9.]{1,3})[, ]+([0-9]{1,3})[, ]+([0-9]{1,3})[, ]+([0-9]+)[ ]*\\)$",
                options: .caseInsensitive
            )
            let argbValues = argbFormat.matches(
                in: argbString,
                range: NSRange(location: 0, length: argbString.utf16.count)
            )
            guard let argbResult = argbValues.first,
                  let aRange = Range(argbResult.range(at: 1), in: argbString),
                  let rRange = Range(argbResult.range(at: 2), in: argbString),
                  let gRange = Range(argbResult.range(at: 3), in: argbString),
                  let bRange = Range(argbResult.range(at: 4), in: argbString),
                  let alpha = CGFloat.parse(String(argbString[aRange])),
                  let red = CGFloat.parse(String(argbString[rRange])),
                  let green = CGFloat.parse(String(argbString[gRange])),
                  let blue = CGFloat.parse(String(argbString[bRange])) else {
                ExponeaSDK.Exponea.logger.log(.warning, message: "Unable to parse ARGB color \(argbString)")
                return nil
            }
            self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
        } catch let error {
            ExponeaSDK.Exponea.logger.log(
                .warning,
                message: "Unable to parse ARGB color \(argbString): \(error.localizedDescription)"
            )
            return nil
        }
    }
    // swiftlint:disable function_body_length
    convenience init?(cssName: String) {
        // any color name from here: https://www.w3.org/wiki/CSS/Properties/color/keywords
        switch cssName.lowercased() {
        case "aliceblue": self.init(hexString: "#f0f8ff")
        case "antiquewhite": self.init(hexString: "#faebd7")
        case "aqua": self.init(hexString: "#00ffff")
        case "aquamarine": self.init(hexString: "#7fffd4")
        case "azure": self.init(hexString: "#f0ffff")
        case "beige": self.init(hexString: "#f5f5dc")
        case "bisque": self.init(hexString: "#ffe4c4")
        case "black": self.init(hexString: "#000000")
        case "blanchedalmond": self.init(hexString: "#ffebcd")
        case "blue": self.init(hexString: "#0000ff")
        case "blueviolet": self.init(hexString: "#8a2be2")
        case "brown": self.init(hexString: "#a52a2a")
        case "burlywood": self.init(hexString: "#deb887")
        case "cadetblue": self.init(hexString: "#5f9ea0")
        case "chartreuse": self.init(hexString: "#7fff00")
        case "chocolate": self.init(hexString: "#d2691e")
        case "coral": self.init(hexString: "#ff7f50")
        case "cornflowerblue": self.init(hexString: "#6495ed")
        case "cornsilk": self.init(hexString: "#fff8dc")
        case "crimson": self.init(hexString: "#dc143c")
        case "cyan": self.init(hexString: "#00ffff")
        case "darkblue": self.init(hexString: "#00008b")
        case "darkcyan": self.init(hexString: "#008b8b")
        case "darkgoldenrod": self.init(hexString: "#b8860b")
        case "darkgray": self.init(hexString: "#a9a9a9")
        case "darkgreen": self.init(hexString: "#006400")
        case "darkgrey": self.init(hexString: "#a9a9a9")
        case "darkkhaki": self.init(hexString: "#bdb76b")
        case "darkmagenta": self.init(hexString: "#8b008b")
        case "darkolivegreen": self.init(hexString: "#556b2f")
        case "darkorange": self.init(hexString: "#ff8c00")
        case "darkorchid": self.init(hexString: "#9932cc")
        case "darkred": self.init(hexString: "#8b0000")
        case "darksalmon": self.init(hexString: "#e9967a")
        case "darkseagreen": self.init(hexString: "#8fbc8f")
        case "darkslateblue": self.init(hexString: "#483d8b")
        case "darkslategray": self.init(hexString: "#2f4f4f")
        case "darkslategrey": self.init(hexString: "#2f4f4f")
        case "darkturquoise": self.init(hexString: "#00ced1")
        case "darkviolet": self.init(hexString: "#9400d3")
        case "deeppink": self.init(hexString: "#ff1493")
        case "deepskyblue": self.init(hexString: "#00bfff")
        case "dimgray": self.init(hexString: "#696969")
        case "dimgrey": self.init(hexString: "#696969")
        case "dodgerblue": self.init(hexString: "#1e90ff")
        case "firebrick": self.init(hexString: "#b22222")
        case "floralwhite": self.init(hexString: "#fffaf0")
        case "forestgreen": self.init(hexString: "#228b22")
        case "fuchsia": self.init(hexString: "#ff00ff")
        case "gainsboro": self.init(hexString: "#dcdcdc")
        case "ghostwhite": self.init(hexString: "#f8f8ff")
        case "gold": self.init(hexString: "#ffd700")
        case "goldenrod": self.init(hexString: "#daa520")
        case "gray": self.init(hexString: "#808080")
        case "green": self.init(hexString: "#008000")
        case "greenyellow": self.init(hexString: "#adff2f")
        case "grey": self.init(hexString: "#808080")
        case "honeydew": self.init(hexString: "#f0fff0")
        case "hotpink": self.init(hexString: "#ff69b4")
        case "indianred": self.init(hexString: "#cd5c5c")
        case "indigo": self.init(hexString: "#4b0082")
        case "ivory": self.init(hexString: "#fffff0")
        case "khaki": self.init(hexString: "#f0e68c")
        case "lavender": self.init(hexString: "#e6e6fa")
        case "lavenderblush": self.init(hexString: "#fff0f5")
        case "lawngreen": self.init(hexString: "#7cfc00")
        case "lemonchiffon": self.init(hexString: "#fffacd")
        case "lightblue": self.init(hexString: "#add8e6")
        case "lightcoral": self.init(hexString: "#f08080")
        case "lightcyan": self.init(hexString: "#e0ffff")
        case "lightgoldenrodyellow": self.init(hexString: "#fafad2")
        case "lightgray": self.init(hexString: "#d3d3d3")
        case "lightgreen": self.init(hexString: "#90ee90")
        case "lightgrey": self.init(hexString: "#d3d3d3")
        case "lightpink": self.init(hexString: "#ffb6c1")
        case "lightsalmon": self.init(hexString: "#ffa07a")
        case "lightseagreen": self.init(hexString: "#20b2aa")
        case "lightskyblue": self.init(hexString: "#87cefa")
        case "lightslategray": self.init(hexString: "#778899")
        case "lightslategrey": self.init(hexString: "#778899")
        case "lightsteelblue": self.init(hexString: "#b0c4de")
        case "lightyellow": self.init(hexString: "#ffffe0")
        case "lime": self.init(hexString: "#00ff00")
        case "limegreen": self.init(hexString: "#32cd32")
        case "linen": self.init(hexString: "#faf0e6")
        case "magenta": self.init(hexString: "#ff00ff")
        case "maroon": self.init(hexString: "#800000")
        case "mediumaquamarine": self.init(hexString: "#66cdaa")
        case "mediumblue": self.init(hexString: "#0000cd")
        case "mediumorchid": self.init(hexString: "#ba55d3")
        case "mediumpurple": self.init(hexString: "#9370db")
        case "mediumseagreen": self.init(hexString: "#3cb371")
        case "mediumslateblue": self.init(hexString: "#7b68ee")
        case "mediumspringgreen": self.init(hexString: "#00fa9a")
        case "mediumturquoise": self.init(hexString: "#48d1cc")
        case "mediumvioletred": self.init(hexString: "#c71585")
        case "midnightblue": self.init(hexString: "#191970")
        case "mintcream": self.init(hexString: "#f5fffa")
        case "mistyrose": self.init(hexString: "#ffe4e1")
        case "moccasin": self.init(hexString: "#ffe4b5")
        case "navajowhite": self.init(hexString: "#ffdead")
        case "navy": self.init(hexString: "#000080")
        case "oldlace": self.init(hexString: "#fdf5e6")
        case "olive": self.init(hexString: "#808000")
        case "olivedrab": self.init(hexString: "#6b8e23")
        case "orange": self.init(hexString: "#ffa500")
        case "orangered": self.init(hexString: "#ff4500")
        case "orchid": self.init(hexString: "#da70d6")
        case "palegoldenrod": self.init(hexString: "#eee8aa")
        case "palegreen": self.init(hexString: "#98fb98")
        case "paleturquoise": self.init(hexString: "#afeeee")
        case "palevioletred": self.init(hexString: "#db7093")
        case "papayawhip": self.init(hexString: "#ffefd5")
        case "peachpuff": self.init(hexString: "#ffdab9")
        case "peru": self.init(hexString: "#cd853f")
        case "pink": self.init(hexString: "#ffc0cb")
        case "plum": self.init(hexString: "#dda0dd")
        case "powderblue": self.init(hexString: "#b0e0e6")
        case "purple": self.init(hexString: "#800080")
        case "red": self.init(hexString: "#ff0000")
        case "rosybrown": self.init(hexString: "#bc8f8f")
        case "royalblue": self.init(hexString: "#4169e1")
        case "saddlebrown": self.init(hexString: "#8b4513")
        case "salmon": self.init(hexString: "#fa8072")
        case "sandybrown": self.init(hexString: "#f4a460")
        case "seagreen": self.init(hexString: "#2e8b57")
        case "seashell": self.init(hexString: "#fff5ee")
        case "sienna": self.init(hexString: "#a0522d")
        case "silver": self.init(hexString: "#c0c0c0")
        case "skyblue": self.init(hexString: "#87ceeb")
        case "slateblue": self.init(hexString: "#6a5acd")
        case "slategray": self.init(hexString: "#708090")
        case "slategrey": self.init(hexString: "#708090")
        case "snow": self.init(hexString: "#fffafa")
        case "springgreen": self.init(hexString: "#00ff7f")
        case "steelblue": self.init(hexString: "#4682b4")
        case "tan": self.init(hexString: "#d2b48c")
        case "teal": self.init(hexString: "#008080")
        case "thistle": self.init(hexString: "#d8bfd8")
        case "tomato": self.init(hexString: "#ff6347")
        case "turquoise": self.init(hexString: "#40e0d0")
        case "violet": self.init(hexString: "#ee82ee")
        case "wheat": self.init(hexString: "#f5deb3")
        case "white": self.init(hexString: "#ffffff")
        case "whitesmoke": self.init(hexString: "#f5f5f5")
        case "yellow": self.init(hexString: "#ffff00")
        case "yellowgreen": self.init(hexString: "#9acd32")
        default:
            ExponeaSDK.Exponea.logger.log(.warning, message: "Unable to parse CSS color \(cssName)")
            return nil
        }
    }
    // swiftlint:enable function_body_length
    static func parse(_ source: String?) -> UIColor? {
        guard let source = source else {
            return nil
        }
        if source.starts(with: "#") {
            return UIColor(hexString: source)
        }
        if source.lowercased().starts(with: "rgba(") {
            return UIColor(rgbaString: source)
        }
        if source.lowercased().starts(with: "argb(") {
            return UIColor(argbString: source)
        }
        if source.lowercased().starts(with: "rgb(") {
            return UIColor(rgbString: source)
        }
        return UIColor(cssName: source)
    }
}

extension CGFloat {
    static func parse(_ source: String?) -> CGFloat? {
        guard let source = source else {
            return nil
        }
        let numberString = source.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        guard let number = Float(numberString) else {
            return nil
        }
        return CGFloat(number)
    }
}

extension UIFont.Weight {
    static func parse(_ source: String?) -> UIFont.Weight? {
        guard let source = source else {
            return nil
        }
        switch source.lowercased() {
        case "normal": return UIFont.Weight.regular
        case "bold": return UIFont.Weight.bold
        case "100": return UIFont.Weight.ultraLight
        case "200": return UIFont.Weight.thin
        case "300": return UIFont.Weight.light
        case "400": return UIFont.Weight.regular
        case "500": return UIFont.Weight.medium
        case "600": return UIFont.Weight.semibold
        case "700": return UIFont.Weight.bold
        case "800": return UIFont.Weight.heavy
        case "900": return UIFont.Weight.black
        default: return UIFont.Weight.regular
        }
    }
}
