//
//  InAppImageComponentConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

public struct InAppImageComponentConfig: Identifiable, Codable {

    public enum SizeType: Equatable, Codable {
        case auto
        case lock(apectRation: CGSize, type: AspectRationType)
        case fullscreen

        init(
            aspectRation: CGSize?,
            size: String?,
            objectFit: String?
        ) {
            switch size?.lowercased() {
            case "auto":
                self = .auto
            case "lock_aspect_ratio":
                if let aspectRation {
                    self = .lock(apectRation: aspectRation, type: .init(input: objectFit))
                } else {
                    self = .auto
                }
            case "full_screen":
                self = .fullscreen
            default:
                self = .auto
            }
        }

        var name: String {
            switch self {
            case .auto:
                return "auto"
            case .lock:
                return "lock"
            case .fullscreen:
                return "fullscreen"
            }
        }
    }

    public enum AspectRationType: Codable {
        case cover
        case fill
        case contain
        case none

        init(input: String?) {
            switch input?.lowercased() {
            case "cover":
                self = .cover
            case "contain":
                self = .contain
            case "fill":
                self = .fill
            default:
                self = .none
            }
        }
    }

    public var id = UUID()
    public let url: URL?
    public var imageSize: CGSize = .zero
    public let size: SizeType
    public let margin: [InAppButtonEdge]
    public let overlayColor: String?
    public let cornerRadius: CGFloat?
    public let isVisible: Bool
    public let isOverlay: Bool

    init(url: URL?, size: SizeType, margin: [InAppButtonEdge], overlayColor: String?, cornerRadius: CGFloat?, isVisible: Bool, isOverlay: Bool) {
        self.url = url
        self.size = size
        self.margin = margin
        self.overlayColor = overlayColor
        self.cornerRadius = cornerRadius
        self.isVisible = isVisible
        self.isOverlay = isOverlay
        self.imageSize = getImageSize(from: url)
    }

    func getImageSize(from url: URL?) -> CGSize {
        if let url,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image.size
        }
        return .zero
    }
}
