//
//  UITableViewCell+SilCellShadow.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 15/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

extension UITableViewCell {

    private func applyShadowMutationsWithoutImplicitAnimation(_ mutations: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mutations()
        CATransaction.commit()
    }

    @objc func addShadowWhenAtTop() {
        applyShadowMutationsWithoutImplicitAnimation {
            let topShadowRect = CGRect(x: bounds.origin.x, y: bounds.origin.y + 1,
                                       width: bounds.size.width, height: bounds.size.height - 3)
            addShadow(withOffset: CGSize(width: SILCellShadowOffset.width, height: 0), radius: SILCellShadowRadius)
            let radiusRect = CGSize(width: CornerRadiusStandardValue, height: CornerRadiusStandardValue)
            self.layer.shadowPath = UIBezierPath(roundedRect: topShadowRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: radiusRect).cgPath
        }
    }

    @objc func addShadowWhenInMid() {
        applyShadowMutationsWithoutImplicitAnimation {
            addShadow(withOffset: CGSize(width: SILCellShadowOffset.width, height: -2),
                      radius: SILCellShadowRadius)
            self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        }
    }

    @objc func addShadowWhenAtBottom() {
        applyShadowMutationsWithoutImplicitAnimation {
            let topShadowRect = CGRect(x: bounds.origin.x, y: bounds.origin.y - 2,
                                       width: bounds.size.width, height: bounds.size.height + 3)
            addShadow(withOffset: CGSize(width: SILCellShadowOffset.width, height: 0), radius: SILCellShadowRadius)
            let radiusRect = CGSize(width: CornerRadiusStandardValue, height: CornerRadiusStandardValue)
            self.layer.shadowPath = UIBezierPath(roundedRect: topShadowRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: radiusRect).cgPath
        }
    }

    @objc func addShadowWhenAlone() {
        applyShadowMutationsWithoutImplicitAnimation {
            self.layer.shadowPath = nil
            addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
        }
    }

    @objc func roundCornersTop() {
        roundCorners([.topLeft, .topRight])
    }

    @objc func roundCornersBottom() {
        roundCorners([.bottomLeft, .bottomRight])
    }

    @objc func roundCornersAll() {
        roundCorners([.allCorners])
    }

    @objc func roundCornersNone() {
        let path = UIBezierPath(rect: self.bounds)
        setMask(path)
    }

    private func roundCorners (_ corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: CornerRadiusStandardValue, height: CornerRadiusStandardValue))
        setMask(path)
    }

    private func setMask(_ bezierPath: UIBezierPath) {
        applyShadowMutationsWithoutImplicitAnimation {
            self.backgroundColor = .clear
            if let existing = self.contentView.layer.mask as? CAShapeLayer {
                existing.path = bezierPath.cgPath
            } else {
                let mask = CAShapeLayer()
                mask.path = bezierPath.cgPath
                self.contentView.layer.mask = mask
            }
        }
    }
}
