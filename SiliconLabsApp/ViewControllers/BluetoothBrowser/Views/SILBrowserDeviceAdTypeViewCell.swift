//
//  SILBrowserDeviceAdTypeViewCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@objcMembers class SILBrowserDeviceAdTypeViewCell: SILCell, SILConfigurableCell {
    
    @IBOutlet weak var adTypeNameLabel: UILabel!
    @IBOutlet weak var adTypeValueLabel: UILabel!
    
    var viewModel : SILAdvertisementDataViewModel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        adTypeNameLabel.text = ""
        adTypeValueLabel.text = ""
        viewModel = nil
    }
    
    func configure() {
        let nameTarget = viewModel?.typeString
        if adTypeNameLabel.text != nameTarget {
            adTypeNameLabel.text = nameTarget
        }
        let valueTarget = viewModel?.valueString
        if adTypeValueLabel.text != valueTarget {
            adTypeValueLabel.text = valueTarget
        }
    }
}
