//
//  SILRoundedButton.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 27/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILRoundedButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = CornerRadiusForButtons {
        didSet {
            self.layer.cornerRadius = cornerRadius
            self.layer.masksToBounds = true
        }
    }

    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    

}
