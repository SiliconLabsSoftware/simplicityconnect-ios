//
//  UITextView+AddHyperLinksToText.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

extension UITextView {

  func addHyperLinksToText(originalAttributedText: NSAttributedString, hyperLinks: [String: String]) {
    let fontAttribute: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 14) ?? UIFont.systemFont(ofSize: 14),
        NSAttributedString.Key.foregroundColor: UIColor(named: "sil_lightTextGreyColor") ?? UIColor.gray
    ]
    let attributedOriginalText = NSMutableAttributedString(string: originalAttributedText.string, attributes: fontAttribute)
    for (hyperLink, urlString) in hyperLinks {
        let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
    }

    self.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor.appPrimaryBrand
    ]
    self.attributedText = attributedOriginalText
  }
}
