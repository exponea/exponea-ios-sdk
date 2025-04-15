//
//  TextWithAttributedString.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import UIKit
import SwiftUI

struct TextWithAttributedString: View {

    @State private var height: CGFloat = .zero
    let config: InAppTextConfigurable
    let isCompressionVertical: Bool
    let width: CGFloat
    let heightCompletion: TypeBlock<CGFloat>?

    init(
        config: InAppTextConfigurable,
        width: CGFloat,
        isCompressionVertical: Bool = false,
        heightCompletion: TypeBlock<CGFloat>? = nil
    ) {
        self.config = config
        self.width = width
        self.isCompressionVertical = isCompressionVertical
        self.heightCompletion = heightCompletion
    }

    var body: some View {
        InternalTextView(
            dynamicHeight: $height,
            config: config,
            isCompressionVertical: isCompressionVertical
        )
        .frame(height: height)
        .valueChanged(value: height) { height in
            self.height = height
            heightCompletion?(height)
        }
        .padding(.bottom, config.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
        .padding(.top, config.padding.first(where: { $0.edge == .top })?.value ?? 0)
        .padding(.leading, config.padding.first(where: { $0.edge == .leading })?.value ?? 0)
        .padding(.trailing, config.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
    }

   struct InternalTextView: UIViewRepresentable {

       @Binding var dynamicHeight: CGFloat

       private let config: InAppTextConfigurable
       private let isCompressionVertical: Bool

       init(
        dynamicHeight: Binding<CGFloat>,
        config: InAppTextConfigurable,
        isCompressionVertical: Bool = false
       ) {
           self._dynamicHeight = dynamicHeight
           self.config = config
           self.isCompressionVertical = isCompressionVertical
       }

       func makeUIView(context: Context) -> UITextView {
           let textView = UITextView()
           textView.isScrollEnabled = false
           textView.isEditable = false
           textView.isSelectable = false
           textView.isUserInteractionEnabled = false
           textView.showsVerticalScrollIndicator = false
           textView.showsHorizontalScrollIndicator = false
           textView.allowsEditingTextAttributes = false
           textView.backgroundColor = .clear
           textView.textContainerInset = .zero
           textView.textContainer.lineFragmentPadding = 0
           if isCompressionVertical {
               textView.textAlignment = .left
               textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
               textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
           } else {
               textView.textAlignment = .justified
               textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
               textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
           }
           return textView
       }

       private func applyStyle() -> NSMutableAttributedString {
           var attributes: [NSAttributedString.Key: Any] = [:]

           if let customFont = config.fontData?.loadedFont {
               attributes[.font] = customFont
           } else {
               attributes[.font] = UIFont.fromStyle(style: config.style, size: Int(config.size))
           }
           attributes[.foregroundColor] = UIColor.parse(config.color) ?? .black

           let attrString = NSMutableAttributedString(string: config.text ?? "", attributes: attributes)

           let paraStyle = NSMutableParagraphStyle()
           paraStyle.alignment = TextAlignment(input: config.alignment).alignment

           if let lineHeight = config.lineHeight {
               let size = CGFloat(config.size)
               let lineHeight = lineHeight - size
               paraStyle.minimumLineHeight = lineHeight < 0 ? 0 : lineHeight
           }

           attrString.addAttribute(
               .paragraphStyle,
               value: paraStyle,
               range: NSRange(location: 0, length: config.text?.count ?? 0)
           )
           return attrString
       }

       func updateUIView(_ uiView: UITextView, context: Context) {
           uiView.attributedText = applyStyle()
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               let height = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
               dynamicHeight = height
           }
       }
   }
}
