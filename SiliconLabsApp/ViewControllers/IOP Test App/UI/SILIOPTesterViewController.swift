//
//  SILIOPTesterViewController.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 06/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit

@objc
@objcMembers
class SILIOPTesterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SILIOPTesterViewModelDelegate {
    
    @IBOutlet weak var allSpace: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var firmwareNameLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var totalTestCases: UILabel!
    @IBOutlet weak var floatingButton: UIButton!
    
    
    private var viewModel: SILIOPTesterViewModel?
    var deviceNameToSearch: String?

    private var disposeBag = SILObservableTokenBag()
    
    private var currentTestState: SILIOPTesterViewModel.TestState?
    private var currentTestScenarioIndex: Int = 0
    
    private static let descriptionFont = UIFont(name: "Stolzl-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
    private static let cellVerticalPadding: CGFloat = 48
    private static let minCellHeight: CGFloat = 80
    // Horizontal overhead between the screen edge and the description label (table margins + cell paddings + status view).
    private static let descriptionWidthOverhead: CGFloat = 127
    private var heightCache: [String: CGFloat] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRedLineBelowNavigationBar()
        self.disposeBag = SILObservableTokenBag()
        self.setupViewModel()
        self.setupFloatingButton()
        self.subscribeToUpdateUINotifications()
        self.floatingButton.layer.cornerRadius = 10
        infoView.addShadow()
        // Bottom inset so the last cell's shadow + rounded corner aren't clipped by the table edge.
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        if let deviceNameToSearch = deviceNameToSearch {
            firmwareNameLabel.text = "  \(deviceNameToSearch)"
        }
        deviceNameLabel.text = "  \(viewModel?.deviceModelName ?? "  Unknown")"
        self.setLeftAlignedTitle("Interoperability Test")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "shareWhite"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(shareTestResult))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unregisterNotifications()
        viewModel?.stopTest()
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(showDocumentPickerView), name: .SILIOPShowFilePicker, object: nil)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .SILIOPShowFilePicker, object: nil)
    }
    
    @IBAction func floatingButtonPressed() {
        if currentTestState! != .running {
            viewModel?.startTest()
        } else {
            showPopupAlert()
        }
    }
    
    func setupFloatingButton() {
        self.floatingButton.setTitle(self.buttonText(), for: .normal)
    }
    
    func buttonText() -> String {
        guard let currentTestState = currentTestState else {
            return "Run Test"
        }
        
        switch(currentTestState) {
        case .initiated, .ended:
            return "Run Test"
        case .running:
            return "Stop Test"
        }
    }
    
    func subscribeToUpdateUINotifications() {
        guard let viewModel = viewModel else { return }
        weak var weakSelf = self
        let updateTableViewSubscription = viewModel.updateTableViewWithCurrentTestScenarioIndex.observe( { index in
            guard let weakSelf = weakSelf else { return }
            let sections = weakSelf.viewModel?.cellViewModels.count ?? 0
            // Clamp Scan/Connect to row 0 so the auto-scroll doesn't chase short-lived early scenarios.
            let targetIndex = index < 2 ? 0 : index
            let activeChanged = weakSelf.currentTestScenarioIndex != targetIndex
            if activeChanged {
                weakSelf.currentTestScenarioIndex = targetIndex
            }
            // Update the visible cell in place — reloadSections() detaches/re-attaches the row and makes it visibly jump.
            if index >= 0 && index < sections,
               let scenarioVM = weakSelf.viewModel?.cellViewModels[index] as? SILIOPTestScenarioCellViewModel,
               scenarioVM.shouldUpdateView,
               let cell = weakSelf.tableView.cellForRow(at: IndexPath(row: 0, section: index)) as? SILIOPTestScenarioCellView {
                UIView.performWithoutAnimation {
                    cell.setViewModel(scenarioVM)
                }
            }
            // Scroll once per scenario transition with .none so already-visible rows stay put.
            if activeChanged && targetIndex >= 0 && targetIndex < sections {
                let indexPath = IndexPath(row: 0, section: targetIndex)
                weakSelf.tableView.scrollToRow(at: indexPath, at: .none, animated: true)
            }
        })
        disposeBag.add(token: updateTableViewSubscription)
        
        let testCasesInProgressSubscription = viewModel.testCasesInProgress.observe( { testCasesInProgress in
            guard let weakSelf = weakSelf else { return }
            weakSelf.totalTestCases.text = "  \(testCasesInProgress) Test Cases"
        })
        disposeBag.add(token: testCasesInProgressSubscription)
        
        let testStateStatusSubscription = viewModel.testStateStatus.observe( { status in
            guard let weakSelf = weakSelf else { return }
            let previousState = weakSelf.currentTestState
            weakSelf.currentTestState = status
            weakSelf.setupFloatingButton()
            // On Run Test, reset visible cells in place to clear stale Pass/Fail badges from a previous run.
            if status == .running && previousState != .running {
                weakSelf.refreshAllVisibleScenarioCells()
            }
        })
        disposeBag.add(token: testStateStatusSubscription)
        
        let bluetoothStateSubscription = viewModel.bluetoothState.observe( { state in
            guard let weakSelf = weakSelf else { return }
            if state == false {
                weakSelf.showBluetoothDisabledAlert()
            }
        })
        disposeBag.add(token: bluetoothStateSubscription)
    }
    
    private func refreshAllVisibleScenarioCells() {
        UIView.performWithoutAnimation {
            for indexPath in tableView.indexPathsForVisibleRows ?? [] {
                guard let cell = tableView.cellForRow(at: indexPath) as? SILIOPTestScenarioCellView,
                      let scenarioVM = viewModel?.cellViewModels[indexPath.section] as? SILIOPTestScenarioCellViewModel else { continue }
                cell.setViewModel(scenarioVM)
            }
        }
    }
    
    private func showPopupAlert() {
        guard self.currentTestState == .running else {
            return
        }
        
        let alert = UIAlertController(title: "Are you sure you want to stop the test?", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .default)
        let okAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            self.viewModel?.endTesting()
        }

        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
 
    @objc func shareTestResult() {
        
        let alert = UIAlertController(title: "Select log file.", message: "", preferredStyle: .alert)
        let debugLog = UIAlertAction(title: "Application Debug Log", style: .default) { (action) in
            self.shareLogFile(logType: "ConsoleLog")
        }
        
        let resultLog = UIAlertAction(title: "Test Result Log", style: .default) { (action) in
            self.shareLogFile(logType: "UILog")
        }
        
       
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alert.addAction(resultLog)
        alert.addAction(debugLog)
        alert.addAction(cancelAction)
        //alert.popoverPresentationController?.sourceView = self.btnShare
        self.present(alert, animated: true, completion: nil)

        
        //Console:
//         let fileSh = viewModel.getConsolLogsFile()
//   
////        if let file = viewModel.getMeshLogsFile() {
////            self.shareTestResultTemp(fileURL: file, fileName: "Application/Mesh Logs")
////        }
//
//        
//        let iopTestLogSubject = "IOP Test Log"
//        
//        let activityViewController = UIActivityViewController(activityItems: [fileSh as Any], applicationActivities: nil)
//        activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
//        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
//        
//        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func shareLogFile(logType: String)  {
        guard let viewModel = viewModel, currentTestState != .initiated else { return }
        if logType == "UILog" {
            viewModel.prepareTestReport()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var filesToShare:[Any] = []
            if logType == "UILog" {
                filesToShare = [viewModel.getReportFile() as Any]
            }else if logType == "ConsoleLog" {
                filesToShare = [viewModel.getConsolLogsFile() as Any]
            }
            
            let iopTestLogSubject = "IOP Test Log"
            
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            activityViewController.setValue(iopTestLogSubject, forKey: "Subject")
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            
            self.present(activityViewController, animated: true, completion: nil)
        }

    }
    
    private func showBluetoothDisabledAlert() {
        let bluetoothDisabledAlert = SILBluetoothDisabledAlert.interoperabilityTest
        self.alertWithOKButton(title: bluetoothDisabledAlert.title, message: bluetoothDisabledAlert.message, completion: { _ in
            self.viewModel?.stopTest()
        })
    }
    
    //MARK: INITIALIZE VIEW MODEL
    
    func setupViewModel() {
        guard let deviceName =  self.deviceNameToSearch else { return }
        self.viewModel = SILIOPTesterViewModel(deviceNameToSearch: deviceName)
        
       self.viewModel?.SILIOPTesterViewModelDelegate = self
    }
    
    func showDocumentPickerView() {
        let documentPickerViewController = SILDocumentPickerViewController(documentTypes: ["public.gbl"], in: .import)
        documentPickerViewController.setupDocumentPickerView()
        documentPickerViewController.delegate = self
        self.present(documentPickerViewController, animated: false, completion: nil)
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellViewModel = self.viewModel?.cellViewModels[indexPath.section] as SILCellViewModel?
        
        guard let cellViewModel = cellViewModel else { return UITableViewCell() }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.reusableIdentifier) as?  SILIOPTestScenarioCellView else { return UITableViewCell() }
        
        cell.setViewModel(cellViewModel)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.cellViewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Use screen width as a stable source so multi-line cell heights don't change between layout passes.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellViewModel = self.viewModel?.cellViewModels[indexPath.section] as? SILIOPTestScenarioCellViewModel else {
            return Self.minCellHeight
        }
        let availableWidth = max(50, UIScreen.main.bounds.width - Self.descriptionWidthOverhead)
        if let cached = heightCache[cellViewModel.description] { return cached }
        let descRect = (cellViewModel.description as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Self.descriptionFont],
            context: nil
        )
        let height = max(Self.minCellHeight, ceil(descRect.height) + Self.cellVerticalPadding)
        heightCache[cellViewModel.description] = height
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        SILTableViewWithShadowCells.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        SILTableViewWithShadowCells.tableView(tableView, viewForHeaderInSection: section, withHeight: 5.0)
    }
}

extension SILIOPTesterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        debugPrint("DID PICK")
        IOPLog().iopLogSwiftFunction(message: "DID PICK")
        self.sendChosenUrl(urls: urls)
    }
    
    private func sendChosenUrl(urls: [URL]) {
        if let gblFile = urls.first {
            let gblFileDict: [String: Any] = ["gblFileUrl": gblFile]
            
            NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: gblFileDict))
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        debugPrint("DID CANCEL")
        IOPLog().iopLogSwiftFunction(message: "DID CANCEL PICKER")
        NotificationCenter.default.post(Notification(name: .SILIOPFileUrlChosen, object: nil, userInfo: nil))
        controller.dismiss(animated: true, completion: nil)
    }
}
//MARK: SILIOPTesterViewModelDelegate
extension SILIOPTesterViewController {
    func notifyAfterAllTest() {
        print("END")
        DispatchQueue.main.async {
            let SILIOPDeviceResetInfoPopupViewControllerObj = SILIOPDeviceResetInfoPopupViewController(nibName: "SILIOPDeviceResetInfoPopupViewController", bundle: nil)
        SILIOPDeviceResetInfoPopupViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(SILIOPDeviceResetInfoPopupViewControllerObj, animated: false)
        }
 
    }
}
