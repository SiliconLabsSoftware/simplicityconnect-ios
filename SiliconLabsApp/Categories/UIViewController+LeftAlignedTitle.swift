//
//  UIViewController+LeftAlignedTitle.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 21/10/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Foundation

extension UIViewController {
    @objc func setLeftAlignedTitle(_ text: String) {
        self.navigationItem.hidesBackButton = true

        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        if let chevron = UIImage(systemName: "chevron.backward", withConfiguration: config) {
            backButton.setImage(chevron.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        backButton.tintColor = .white
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 16)
        backButton.addTarget(self, action: #selector(leftAlignedTitleBackAction), for: .touchUpInside)
        let backItem = UIBarButtonItem(customView: backButton)

        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Stolzl-Medium", size: 17) ?? .systemFont(ofSize: 17)

        let titleItem = UIBarButtonItem(customView: titleLabel)
        self.navigationItem.leftBarButtonItems = [backItem, titleItem]
        self.navigationItem.title = ""
    }

    @objc private func leftAlignedTitleBackAction() {
        self.navigationController?.popViewController(animated: true)
    }
        
    func setCustomBackButton(title: String = "Back", action: Selector) {
        self.navigationItem.hidesBackButton = true
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        if let backImage = UIImage(systemName: "chevron.backward") {
            backButton.setImage(backImage, for: .normal)
        }
        backButton.setTitle(title, for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Stolzl-Medium", size: 17) ?? .systemFont(ofSize: 17)
        backButton.tintColor = .white
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: action, for: .touchUpInside)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 8)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        let backBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = backBarButton
    }
}
