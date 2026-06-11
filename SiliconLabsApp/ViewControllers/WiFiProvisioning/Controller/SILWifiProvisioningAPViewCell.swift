//
//  SILWifiProvisioningAPViewCell.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 25/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit

class SILWifiProvisioningAPViewCell: UITableViewCell {

    @IBOutlet weak var wifiSignalImg: UIImageView!
    @IBOutlet weak var apNameLbl: UILabel!
    @IBOutlet weak var securityTypeLbl: UILabel!
    @IBOutlet weak var bssidLbl: UILabel!
    @IBOutlet weak var rssiLbl: UILabel!
    @IBOutlet weak var cardView: UIView!

     
   private let bestRange = -48...0
   private let betterRange = -75...(-49)
   private let badRange = -1000...(-76)

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        contentView.clipsToBounds = false
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.layer.cornerRadius = 10
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.15
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func updateAPCell(cellData: ScanResult) {
      
        if let rssiVal = Int(cellData.rssi) {
            switch rssiVal {
            case bestRange:
                wifiSignalImg.image = UIImage(named: "Wifisignal_3")
            case betterRange:
                wifiSignalImg.image = UIImage(named: "Wifisignal_2")
            case badRange:
                wifiSignalImg.image = UIImage(named: "Wifisignal_1")
            default:
                wifiSignalImg.image = UIImage(named: "Wifisignal_1")
            }
        }

        apNameLbl.text = cellData.ssid
        securityTypeLbl.text = cellData.securityType
        bssidLbl.text = cellData.bssid
        rssiLbl.text = "rssi: \(cellData.rssi)"
    }
    
}
