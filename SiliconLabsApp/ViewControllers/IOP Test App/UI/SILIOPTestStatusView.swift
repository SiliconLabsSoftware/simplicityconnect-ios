//
//  SILIOPTestStatusView.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 15.4.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTestStatusView: UIView {
    @IBOutlet weak var testStatusImageView: UIImageView!
    @IBOutlet weak var testStatusLabel: UILabel!
    @IBOutlet weak var imageHeightContraint: NSLayoutConstraint!
    
    let imageNamesForStatus = (inProgress: "debug_loading_spinner",
                               passed: "icon - checkmark",
                               failed: "cancelScanning")
    
    func update(newStatus: SILTestStatus) {
        // Silence implicit layout animations from constraint/isHidden flips so the parent row stays stable.
        UIView.performWithoutAnimation {
            applyStatus(newStatus)
            self.layoutIfNeeded()
        }
    }
    
    private func applyStatus(_ newStatus: SILTestStatus) {
        switch newStatus {
        case .waiting:
            testStatusLabel.isHidden = false
            NSLayoutConstraint.deactivate([imageHeightContraint])
            testStatusImageView.isHidden = true
            testStatusImageView.layer.removeAllAnimations()
            testStatusLabel.text = "Waiting"
            testStatusLabel.textColor = UIColor.sil_subtitleText()

        case .inProgress:
            testStatusLabel.isHidden = true
            NSLayoutConstraint.activate([imageHeightContraint])
            testStatusImageView.isHidden = false
            testStatusImageView.image = UIImage(named: imageNamesForStatus.inProgress)
            UIView.addContinuousRotationAnimation(to: testStatusImageView.layer, withFullRotationDuration: 2, forKey: "testingI")

        case .passed(details: _):
            testStatusLabel.isHidden = false
            NSLayoutConstraint.activate([imageHeightContraint])
            testStatusImageView.isHidden = false
            testStatusImageView.layer.removeAllAnimations()
            testStatusLabel.text = "Pass"
            let greenColor = UIColor(named: "sil_regularGreenColor") ?? .systemGreen
            testStatusLabel.textColor = greenColor
            testStatusImageView.image = UIImage(named: imageNamesForStatus.passed)?.withRenderingMode(.alwaysTemplate)
            testStatusImageView.tintColor = greenColor
            
        case .failed(reason: _):
            testStatusLabel.isHidden = false
            NSLayoutConstraint.activate([imageHeightContraint])
            testStatusImageView.isHidden = false
            testStatusImageView.layer.removeAllAnimations()
            testStatusLabel.text = "Fail"
            testStatusLabel.textColor = UIColor(named: "sil_siliconLabsRedColor") ?? .systemRed
            testStatusImageView.image = UIImage(named: imageNamesForStatus.failed)
            
        case .unknown(reason: _):
            testStatusLabel.isHidden = false
            NSLayoutConstraint.deactivate([imageHeightContraint])
            testStatusImageView.isHidden = true
            testStatusImageView.layer.removeAllAnimations()
            testStatusLabel.text = "N/A"
            testStatusLabel.textColor = UIColor.sil_subtitleText()
            
        case .none:
            break
        }
    }
}
