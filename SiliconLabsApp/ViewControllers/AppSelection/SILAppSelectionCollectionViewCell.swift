//
//  SILAppSelectionCollectionViewCell.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 13/05/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

class SILAppSelectionCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var roundedView: UIView?
    
    @IBOutlet weak var imageView: UIView?
    @IBOutlet weak var iconImageView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var demoBannerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearence()
    }

    private func setupCellAppearence() {
        setupIconImageView()
        setupCellRoundedAppearance()
        setupDemoBanner()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        backgroundColor = UIColor.clear
        addShadow(withOffset: SILCellShadowOffset, radius: SILCellShadowRadius)
    }

    private func setupIconImageView() {
        iconImageView?.layer.masksToBounds = true
        iconImageView?.backgroundColor = .white
        iconImageView?.tintColor = .appPrimaryBrand
    }

    private func setupCellRoundedAppearance() {
        roundedView?.layer.masksToBounds = true
        roundedView?.layer.cornerRadius = CGFloat(CornerRadiusStandardValue)
    }

    private func setupDemoBanner() {
        guard let banner = demoBannerView else { return }
        banner.layer.cornerRadius = 4
        banner.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
        banner.layer.masksToBounds = true
        banner.superview?.bringSubviewToFront(banner)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
//        imageView = nil
//        iconImageView = nil
//        titleLabel = nil
//        descriptionLabel = nil
    }

    func setFieldsIn(_ appData: SILApp?) {
        titleLabel?.text = appData?.title
        titleLabel?.textColor = .appPrimaryText
        descriptionLabel?.text = appData?.appDescription
        iconImageView?.image = UIImage(named: appData?.imageName ?? "")?.withRenderingMode(.alwaysTemplate)
        iconImageView?.tintColor = .appPrimaryBrand
    }
}
