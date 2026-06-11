//
//  SILIOPTestDeviceSelectorController.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/11/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

class SILIOPTestDeviceSelectorController : UIViewController, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILIOPPopupDelegate {
    
    @IBOutlet weak var floatingButton: UIButton!
    private var devicePopoverController: WYPopoverController?
    private var infoPopoverController: WYPopoverController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.floatingButton.layer.cornerRadius = 10
    }
    
    func deviceSelectionViewController(_ viewController: SILDeviceSelectionViewController!, didSelect peripheral: SILDiscoveredPeripheral!) {
        self.devicePopoverController?.dismissPopover(animated: true) { [self] in
            self.devicePopoverController = nil
            if let deviceName = peripheral.advertisedLocalName {
                let storyboard = UIStoryboard(name: "SILIOPTest", bundle: nil)
                let viewController = (storyboard.instantiateInitialViewController() as! SILIOPTesterViewController)
                viewController.deviceNameToSearch = deviceName
                UserDefaults.standard.setValue("\(peripheral.uuid.uuidString)", forKey: "deviceUUIDToConnect")
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    func didDismissDeviceSelectionViewController() {
        self.devicePopoverController?.dismissPopover(animated: true)
    }
    //IOP device name...
    @IBAction func showDeviceSelection() {
        self.presentDeviceSelectionViewController(app: SILApp.iopTest(), shouldConnectWithPeripheral: false, animated: true) {
            $0?.advertisedLocalName?.contains("IOP_Test_1") ?? false
        }
    }
   
    func didTappedCancelButton() {
        self.dismissPopup()
    }
    
    func presentInfoPopup(animated: Bool) {
        let infoPopup = SILIOPInfoPopup()
        infoPopup.delegate = self
        self.infoPopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: infoPopup, presenting: self, delegate: self, animated: true)
    }
    
    private func dismissPopup() {
        self.infoPopoverController?.dismissPopover(animated: true) {
            self.infoPopoverController = nil
        }
    }
    
    private func presentDeviceSelectionViewController(app: SILApp!, shouldConnectWithPeripheral shouldConnect: Bool = true, animated: Bool,
                                                       filter: DiscoveredPeripheralFilter? = nil) {
         var viewModel: SILDeviceSelectionViewModel?
         if let filter = filter {
             viewModel = SILDeviceSelectionViewModel(appType: app, withFilter: filter)
         } else {
             viewModel = SILDeviceSelectionViewModel(appType: app)
         }
         let selectionViewController = SILDeviceSelectionViewController(deviceSelectionViewModel: viewModel!, shouldConnect: shouldConnect)
         selectionViewController.centralManager = SILBrowserConnectionsViewModel.sharedInstance()!.centralManager!
         selectionViewController.delegate = self
         self.devicePopoverController = WYPopoverController.sil_presentCenterPopover(withContentViewController: selectionViewController, presenting: self,delegate: self, animated: true)
     }
}
