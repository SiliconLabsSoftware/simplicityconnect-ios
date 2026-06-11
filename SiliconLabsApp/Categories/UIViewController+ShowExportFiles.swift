//
//  UIViewController+ShowExportFiles.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 07/04/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showSharingExportFiles(filesToShare: [URL], subject: String, sourceView: UIView, sourceRect: CGRect, completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler?) {
        let filesToShare = filesToShare
        let gattConfiguratorSubject = subject
        
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.appPrimaryBrand], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.appPrimaryBrand
        activityViewController.setValue(gattConfiguratorSubject, forKey: "Subject")
        activityViewController.completionWithItemsHandler = completionWithItemsHandler
        
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        self.present(activityViewController, animated: true, completion: nil)
    }
}

