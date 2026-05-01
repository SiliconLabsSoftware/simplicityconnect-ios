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
        viewModel = nil
    }
    
    func setViewModel(_ viewModel: SILCellViewModel) {
        let scenarioVM = viewModel as! SILIOPTestScenarioCellViewModel
        self.viewModel = scenarioVM
        testTitleLabel.text = scenarioVM.name
        testDescriptionLabel.text = scenarioVM.description
        // Always refresh status (spinner/pass/fail) on reload — pairing may re-enter .inProgress while table reloads.
        testStatusView.update(newStatus: scenarioVM.status)
    }
}
