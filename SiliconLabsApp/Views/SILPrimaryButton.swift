//
//  SILPrimaryButton.swift
//  BlueGecko
//
//  Created by Michał Lenart on 23/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILPrimaryButton: UIButton {
    private static let primaryColor = UIColor.appPrimaryBrand
    private static let disabledColor = UIColor.lightGray
    
    private let shadowLayer = CAShapeLayer()
    
    @IBInspectable var cornerRadius: CGFloat = 10 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 14.0 {
        didSet {
            setupTitleFont()
        }
    }
    
    @IBInspectable var hasBackground: Bool = true {
        didSet {
            setupTitleColor()
            setupBackground()
        }
    }
    
    @IBInspectable var hasBorder: Bool = false {
        didSet {
            setupBorder()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            setupBackground()
            setupBorder()
            setupTitleColor()
        }
    }
    
    override func awakeFromNib() {
        setupAppearance()
    }
    
    override func prepareForInterfaceBuilder() {
        setupAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        setupShadow()
    }
    
    private func setupAppearance() {
        setupStaticAppearance()
        setupTitleColor()
        setupTitleFont()
        setupBackground()
        setupShadow()
    }
    
    private func setupStaticAppearance() {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layer.insertSublayer(shadowLayer, at: 0)
    }
    
    private func setupTitleColor() {
        if hasBackground {
            setTitleColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.lightGray, for: .highlighted)
            setTitleColor(UIColor.white, for: .disabled)
        } else {
            setTitleColor(Self.primaryColor, for: .normal)
            setTitleColor(UIColor.lightGray, for: .highlighted)
            setTitleColor(Self.disabledColor, for: .disabled)
        }
    }
        
    private func setupTitleFont() {
        titleLabel?.font = UIFont(name: "Stolzl-Medium", size: fontSize)
    }
    
    private func setupBackground() {
        if hasBackground {
            self.backgroundColor = isEnabled ? Self.primaryColor : Self.disabledColor
            self.tintColor = isEnabled ? Self.primaryColor : Self.disabledColor
        } else {
            self.backgroundColor = UIColor.white
            self.tintColor = isEnabled ? Self.primaryColor : Self.disabledColor
        }
    }
    
    private func setupBorder() {
        if hasBorder {
            layer.borderWidth = 2
            layer.borderColor = isEnabled ? Self.primaryColor.cgColor : Self.disabledColor.cgColor
        } else {
            layer.borderWidth = 0
        }
    }
    
//    override var intrinsicContentSize: CGSize {
//        var size = super.intrinsicContentSize
//        size.height = max(size.height, 30)
//        return size
//    }
    
    private func setupShadow() {
        if hasBackground {
            shadowLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
            shadowLayer.fillColor = backgroundColor?.cgColor
            shadowLayer.shadowOffset = .zero
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowRadius = isHighlighted ? 2 : 1
            shadowLayer.shadowOpacity = 0
        } else {
            shadowLayer.shadowOpacity = 0
        }
    }
}
