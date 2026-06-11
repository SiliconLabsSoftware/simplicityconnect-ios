//
//  SILSwitch.swift
//  BlueGecko
//
//  Created by Michał Lenart on 30/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
class SILSwitch: UIControl {
    
    @IBInspectable
    public var onColor: UIColor = UIColor.appPrimaryBrand
    
    @IBInspectable
    public var offColor: UIColor = UIColor.lightGray
    
    @IBInspectable
    public var isOn: Bool = true {
        didSet {
            updateSwitchState()
        }
    }
    
    private var trackView: UIView!
    private var switchView: UIView!
    
    private var leftConstraint: NSLayoutConstraint!
    
    /// Vertical inset of the track from the control bounds so the knob
    /// visually appears larger than the track (matches the new design).
    private let trackVerticalInset: CGFloat = 4
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        initView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let track = trackView {
            track.layer.cornerRadius = track.bounds.height / 2
        }
        if let knob = switchView {
            knob.layer.cornerRadius = knob.bounds.height / 2
            knob.layer.shadowPath = UIBezierPath(roundedRect: knob.bounds,
                                                 cornerRadius: knob.bounds.height / 2).cgPath
        }
        updateSwitchState()
    }
    
    private func initView() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
        
        backgroundColor = .clear
        layer.cornerRadius = 0
        clipsToBounds = false
        
        trackView = UIView()
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.isUserInteractionEnabled = false
        addSubview(trackView)
        
        switchView = UIView()
        switchView.translatesAutoresizingMaskIntoConstraints = false
        switchView.backgroundColor = UIColor.white
        switchView.layer.borderWidth = 1
        switchView.layer.shadowColor = UIColor.black.cgColor
        switchView.layer.shadowOpacity = 0.20
        switchView.layer.shadowRadius = 2
        switchView.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(switchView)
        
        leftConstraint = NSLayoutConstraint(item: switchView!,
                                            attribute: .leading,
                                            relatedBy: .equal,
                                            toItem: self,
                                            attribute: .leading,
                                            multiplier: 1,
                                            constant: 0)
        
        addConstraints([
            NSLayoutConstraint(item: trackView!, attribute: .leading, relatedBy: .equal,
                               toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: trackView!, attribute: .trailing, relatedBy: .equal,
                               toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: trackView!, attribute: .top, relatedBy: .equal,
                               toItem: self, attribute: .top, multiplier: 1, constant: trackVerticalInset),
            NSLayoutConstraint(item: trackView!, attribute: .bottom, relatedBy: .equal,
                               toItem: self, attribute: .bottom, multiplier: 1, constant: -trackVerticalInset),
            
            NSLayoutConstraint(item: switchView!, attribute: .width, relatedBy: .equal,
                               toItem: self, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: switchView!, attribute: .height, relatedBy: .equal,
                               toItem: self, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: switchView!, attribute: .centerY, relatedBy: .equal,
                               toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
            
            leftConstraint,
        ])
        leftConstraint.isActive = true
        updateSwitchState()
    }
    
    @objc private func onTap(sender: UITapGestureRecognizer) {
        isOn = !isOn
        sendActions(for: .valueChanged)
    }
    
    private func updateSwitchState() {
        if isOn {
            leftConstraint?.constant = bounds.width - bounds.height
        } else {
            leftConstraint?.constant = 0
        }
        UIView.animate(withDuration: 0.2, animations: {
            let stateColor = self.isOn ? self.onColor : self.offColor
            self.trackView?.backgroundColor = stateColor
            self.switchView?.layer.borderColor = stateColor.cgColor
            self.layoutIfNeeded()
        })
    }
}
