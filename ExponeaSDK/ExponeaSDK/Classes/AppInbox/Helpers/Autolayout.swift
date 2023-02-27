//
//  Autolayout.swift
//  ExponeaSDK
//
//  Created by Ankmara on 24.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit

enum ConstraintType {
    case leading
    case trailing
    case top
    case bottom
}

extension UIView {

    @discardableResult
    func padding(horizontalConstant: CGFloat = 0) -> Self {
        if horizontalConstant > 0 {
            return padding(.leading, .trailing, constant: horizontalConstant)
        } else {
            return padding(.leading, .trailing, constant: horizontalConstant)
                    .padding(.top, .bottom, constant: 0)
        }
    }

    @discardableResult
    func center() -> Self {
        guard let superview = superview else {
            assertionFailure("No added to superview")
            return self
        }
        resizable()
        var constraints: [NSLayoutConstraint] = []
        constraints.append(self.centerXAnchor.constraint(equalTo: superview.centerXAnchor))
        constraints.append(self.centerYAnchor.constraint(equalTo: superview.centerYAnchor))
        NSLayoutConstraint.activate(constraints)
        return self
    }

    @discardableResult
    func centerY() -> Self {
        guard let superview = superview else {
            assertionFailure("No added to superview")
            return self
        }
        resizable()
        var constraints: [NSLayoutConstraint] = []
        constraints.append(self.centerYAnchor.constraint(equalTo: superview.centerYAnchor))
        NSLayoutConstraint.activate(constraints)
        return self
    }

    @discardableResult
    func padding(_ constraintType: ConstraintType..., constant: CGFloat) -> Self {
        guard let superview = superview else {
            assertionFailure("No added to superview")
            return self
        }
        resizable()
        var constraints: [NSLayoutConstraint] = []
        constraintType.forEach { type in
            switch type {
            case .trailing:
                constraints.append(self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -constant))
            case .leading:
                constraints.append(self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: constant))
            case .top:
                constraints.append(self.topAnchor.constraint(equalTo: superview.topAnchor, constant: constant))
            case .bottom:
                constraints.append(self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -constant))
            }
        }
        NSLayoutConstraint.activate(constraints)
        return self
    }
    
    @discardableResult
    func closePadding(constant: CGFloat) -> Self {
        guard let superview = superview else {
            assertionFailure("No added to superview")
            return self
        }
        resizable()
        var constraints: [NSLayoutConstraint] = []
        constraints.append(self.bottomAnchor.constraint(greaterThanOrEqualTo: superview.bottomAnchor, constant: -constant))
        NSLayoutConstraint.activate(constraints)
        return self
    }

    @discardableResult
    func padding<TargetView: UIView>(_ targetView: TargetView, _ constraintType: ConstraintType..., constant: CGFloat) -> Self {
        resizable()
        var constraints: [NSLayoutConstraint] = []
        constraintType.forEach { type in
            switch type {
            case .trailing:
                constraints.append(self.trailingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: -constant))
            case .leading:
                constraints.append(self.leadingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: constant))
            case .top:
                constraints.append(self.topAnchor.constraint(equalTo: targetView.bottomAnchor, constant: constant))
            case .bottom:
                constraints.append(self.bottomAnchor.constraint(equalTo: targetView.topAnchor, constant: constant))
            }
        }
        NSLayoutConstraint.activate(constraints)
        return self
    }

    @discardableResult
    func frame(minWidth: CGFloat? = nil, width: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, height: CGFloat? = nil, maxHeight: CGFloat? = nil) -> Self {
        resizable()
        var constraints: [NSLayoutConstraint] = []
        if let minWidth = minWidth {
            constraints.append(self.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth))
        }
        if let width = width {
            constraints.append(self.widthAnchor.constraint(equalToConstant: width))
        }
        if let maxWidth = maxWidth {
            constraints.append(self.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth))
        }
        if let minHeight = minHeight {
            constraints.append(self.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight))
        }
        if let height = height {
            constraints.append(self.heightAnchor.constraint(equalToConstant: height))
        }
        if let maxHeight = maxHeight {
            constraints.append(self.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight))
        }
        NSLayoutConstraint.activate(constraints)
        return self
    }

    @discardableResult
    func resizable() -> Self {
        if translatesAutoresizingMaskIntoConstraints == true {
            translatesAutoresizingMaskIntoConstraints = false
        }
        return self
    }
}
