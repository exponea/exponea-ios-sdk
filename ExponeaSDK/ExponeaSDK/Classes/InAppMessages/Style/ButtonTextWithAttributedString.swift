//
//  ButtonTextWithAttributedString.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import SwiftUI

struct ButtonTextWithAttributedString: View {
    
    @State private var height: CGFloat = .zero
    let config: InAppButtonConfig
    let isCompressionVertical: Bool
    
    init(
        config: InAppButtonConfig,
        isCompressionVertical: Bool = false,
        heightCompletion: TypeBlock<CGFloat>? = nil
    ) {
        self.config = config
        self.isCompressionVertical = isCompressionVertical
    }
    
    var body: some View {
        InternalTextView(
            dynamicHeight: $height,
            config: config,
            isCompressionVertical: isCompressionVertical
        )
        .frame(height: height)
        .padding(.bottom, config.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
        .padding(.top, config.padding.first(where: { $0.edge == .top })?.value ?? 0)
        .padding(.trailing, config.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
        .padding(.leading, config.padding.first(where: { $0.edge == .leading })?.value ?? 0)
    }

   struct InternalTextView: UIViewRepresentable {

       @Binding var dynamicHeight: CGFloat

       private let config: InAppButtonConfig
       private let isCompressionVertical: Bool
       private var isFontLoaded = false

       init(
        dynamicHeight: Binding<CGFloat>,
        config: InAppButtonConfig,
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
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
           return textView
       }

       private func applyStyle() -> NSMutableAttributedString {
           var attributes: [NSAttributedString.Key: Any] = [:]

           if let customFont = config.fontData?.loadedFont {
               attributes[.font] = customFont
           } else {
               attributes[.font] = UIFont.fromStyle(style: config.style, size: Int(config.size))
           }
           attributes[.foregroundColor] = UIColor.parse(config.textColor) ?? .black

           let attrString = NSMutableAttributedString(string: config.title, attributes: attributes)

           let paraStyle = NSMutableParagraphStyle()
           paraStyle.alignment = TextAlignment(input: config.textAlignment?.rawValue).alignment

           if let lineHeight = config.lineHeight {
               paraStyle.minimumLineHeight = lineHeight
           }

           attrString.addAttribute(
               .paragraphStyle,
               value: paraStyle,
               range: NSRange(location: 0, length: config.title.count)
           )
           return attrString
       }

       func updateUIView(_ uiView: UITextView, context: Context) {
           guard uiView.attributedText.length == 0 else { return }
           uiView.attributedText = applyStyle()
           DispatchQueue.main.async {
               dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
           }
       }
   }
}
