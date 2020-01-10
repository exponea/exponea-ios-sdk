//
//  UIColor+FromHexString.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 03/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

extension UIColor {
    convenience init(fromHexString: String) {
        var cString: String = fromHexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue: UInt32 = 0

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count == 6 {
            Scanner(string: cString).scanHexInt32(&rgbValue)
        }

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
