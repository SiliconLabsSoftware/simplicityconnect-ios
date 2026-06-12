//
//  SILBrowserButton.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILBrowserButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = CornerRadiusForButtons
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupOutlineStyle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
    private func setupOutlineStyle() {
        // Remove any iOS 15+ button configuration that might override styling
        if #available(iOS 15.0, *) {
            self.configuration = nil
        }
        
        let redColor = UIColor(named: "sil_siliconLabsRedColor") ?? .systemRed
        
        // Set outline button style - white background with red border and red text
        self.backgroundColor = .white
        self.setTitleColor(redColor, for: .normal)
        self.setTitleColor(redColor.withAlphaComponent(0.7), for: .highlighted)
        self.layer.borderWidth = 1.0
        self.layer.borderColor = redColor.cgColor
        self.tintColor = redColor
    }

}
