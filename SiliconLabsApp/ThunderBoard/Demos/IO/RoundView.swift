//
//  RoundView.swift
//  Thunderboard
//
//  Created by Jan Wisniewski on 11/02/2020.
//  Copyright © 2020 Silicon Labs. All rights reserved.
//

import UIKit

@IBDesignable
class RoundView: UIView {
    
    @IBInspectable var colorOff: UIColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
    @IBInspectable var colorOn: UIColor = #colorLiteral(red: 0, green: 0.7254901961, blue: 0.4392156863, alpha: 1)

    @IBInspectable var isOn: Bool = false {
        didSet {
            backgroundColor = self.isOn ? colorOn : colorOff
        }
    }
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = self.bounds.size.height/2.0
        self.layer.masksToBounds = true
    }

}
