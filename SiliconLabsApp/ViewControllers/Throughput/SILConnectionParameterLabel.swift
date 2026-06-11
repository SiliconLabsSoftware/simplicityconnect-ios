//
//  SILConnectionParameterLabel.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 14.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILConnectionParameterLabel: UIView {
    var labelFont: UIFont = UIFont.stolzlMedium(size: 14.0) ?? UIFont.systemFont(ofSize: 14.0, weight: .medium)
    var valueFont: UIFont = UIFont.stolzlRegular(size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
    
    private let labelLabel = UILabel()
    private let colonLabel = UILabel()
    private let valueLabel = UILabel()
    
    var text: String? {
        didSet {
            updateLabels()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        labelLabel.translatesAutoresizingMaskIntoConstraints = false
        colonLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(labelLabel)
        addSubview(colonLabel)
        addSubview(valueLabel)
        
        labelLabel.textAlignment = .right
        colonLabel.textAlignment = .center
        valueLabel.textAlignment = .left
        
        labelLabel.textColor = UIColor.sil_primaryText()
        colonLabel.textColor = UIColor.sil_primaryText()
        valueLabel.textColor = UIColor.sil_primaryText()
        
        labelLabel.font = labelFont
        colonLabel.font = labelFont
        valueLabel.font = valueFont
        
        colonLabel.text = ":"
        
        NSLayoutConstraint.activate([
            // Label: right side ends at center
            labelLabel.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -2),
            labelLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            
            // Colon: at center
            colonLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            colonLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            colonLabel.widthAnchor.constraint(equalToConstant: 8),
            
            // Value: left side starts after colon
            valueLabel.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 6),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }
    
    private func updateLabels() {
        guard let text = text else {
            labelLabel.text = nil
            valueLabel.text = nil
            return
        }
        
        let components = text.components(separatedBy: ":")
        
        if components.count >= 2 {
            labelLabel.text = components[0].trimmingCharacters(in: .whitespaces)
            valueLabel.text = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
        } else {
            labelLabel.text = text
            valueLabel.text = nil
        }
        
        labelLabel.font = labelFont
        colonLabel.font = labelFont
        valueLabel.font = valueFont
    }
}
