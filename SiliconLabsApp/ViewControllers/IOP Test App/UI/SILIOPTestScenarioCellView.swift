//
//  SILIOPTestScenarioCellView.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 02/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import UIKit

class SILIOPTestScenarioCellView: UITableViewCell, SILCellView {
    @IBOutlet weak var testTitleLabel: UILabel!
    @IBOutlet weak var testDescriptionLabel: UILabel!
    @IBOutlet weak var testStatusView: SILIOPTestStatusView!
    
    private var viewModel: SILIOPTestScenarioCellViewModel? {
        didSet {
            if let viewModel = viewModel, viewModel.shouldUpdateView {
                testStatusView.update(newStatus: viewModel.status)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        let scenarioVM = viewModel as! SILIOPTestScenarioCellViewModel
        self.viewModel = scenarioVM
        // Skip redundant text writes to avoid invalidating intrinsic content size on each reload.
        if testTitleLabel.text != scenarioVM.name {
            testTitleLabel.text = scenarioVM.name
        }
        if testDescriptionLabel.text != scenarioVM.description {
            testDescriptionLabel.text = scenarioVM.description
        }
        testStatusView.update(newStatus: scenarioVM.status)
    }
}
