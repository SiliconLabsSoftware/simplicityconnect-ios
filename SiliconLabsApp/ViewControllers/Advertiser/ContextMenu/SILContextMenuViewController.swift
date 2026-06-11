//
//  SILContextMenuViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 05/11/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

class SILContextMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let CellHeight: CGFloat = 30.0
    static let NoDataAvailableTitle = "No data types available to add"
    
    @IBOutlet weak var tableView: UITableView!
    
    var options: [ContextMenuOption]!
    var sourceViewWidth: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Replace a fully-disabled option list with a single "No data available" placeholder row.
        // Keep it enabled so its label stays visible (tapping just dismisses, since the callback is empty).
        if options.allSatisfy({ !$0.enabled }) {
            options = [ContextMenuOption(title: Self.NoDataAvailableTitle, callback: {})]
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        // Round popup corners.
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        tableView.layer.cornerRadius = 5
        tableView.layer.masksToBounds = true
        
        updatePreferredContentSize()
    }
    
    private func updatePreferredContentSize() {
        var width = CGFloat(0)
        if let sourceViewWidth = sourceViewWidth {
            width = sourceViewWidth
        } else {
            let widthWithoutMargin = options
                .map({ option in
                    return option.title.size(withAttributes: [
                        .font: UIFont(name: "Stolzl-Regular", size: 17)!
                    ]).width
                }).max() ?? 0
            width = widthWithoutMargin + 48
        }

        let height = CGFloat(options.count) * Self.CellHeight

        preferredContentSize = CGSize(width: width, height: height)
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = options[indexPath.row]
        dismiss(animated: false, completion: nil)
        
        DispatchQueue.main.async {
            option.callback()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Self.CellHeight
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SILContextMenuCellView", for: indexPath) as! SILContextMenuCellView
        let option = options[indexPath.row]
        
        cell.title.text = option.title
        cell.title.isEnabled = option.enabled
        cell.isUserInteractionEnabled = option.enabled
        
        return cell
    }
}
