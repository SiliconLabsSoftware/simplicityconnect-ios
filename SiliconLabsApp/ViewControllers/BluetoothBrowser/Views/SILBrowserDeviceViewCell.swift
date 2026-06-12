//
//  SILBrowserDeviceViewCellTableViewCell.swift
//  BlueGecko
//
//  Created by Jan Wisniewski on 03/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

@IBDesignable
@objcMembers
class SILBrowserDeviceViewCell: SILCell, SILConfigurableCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var favouritesButton: UIButton?
    @IBOutlet weak var connectButton: SILBrowserButton!
    @IBOutlet weak var btImageView: UIImageView!
    @IBOutlet weak var wifiImageView: UIImageView!
    @IBOutlet weak var beaconImageView: UIImageView!
    @IBOutlet weak var connectableLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var beaconLabel: UILabel!
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var advertisingIntervalLabel: UILabel!
    @IBOutlet weak var affordanceImage: UIImageView?
    
    weak var delegate: SILBrowserDeviceViewCellDelegate?
    var viewModel : SILDiscoveredPeripheralDisplayDataViewModel? 
    
    private static let favouriteStarImage: UIImage? = {
        guard let original = UIImage(named: "icon - star - on") else { return nil }
        let targetSize = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.withRenderingMode(.alwaysTemplate)
    }()

    private static let chevronImage: UIImage? = UIImage(systemName: "chevron.down")

    // Cached state so we only mutate `transform` when isExpanded changes.
    private var lastAppliedIsExpanded: Bool?

    override func awakeFromNib() {
        super.awakeFromNib()
        connectingIndicator.isHidden = true
        setAppearanceForConnectButton(connected: false, connectable: false)
        configureFavouriteButtonImage()
        updateFavouriteAppearance()
    }

    private func configureFavouriteButtonImage() {
        guard let button = favouritesButton, let image = Self.favouriteStarImage else { return }
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.setImage(image, for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        button.adjustsImageWhenHighlighted = false
    }

    private func updateFavouriteAppearance() {
        guard let button = favouritesButton else { return }
        let red = UIColor(named: "sil_siliconLabsRedColor") ?? .systemRed
        let primaryText = UIColor(named: "sil_primaryTextColor") ?? .label
        let target: UIColor = button.isSelected ? red : primaryText
        // Avoid implicit CALayer animation by only writing when the value
        // actually changes.
        if button.tintColor != target {
            button.tintColor = target
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        viewModel = nil
        lastAppliedIsExpanded = nil
    }

    private func configureExpandedArrow(_ isExpanded: Bool) {
        guard let imageView = affordanceImage else { return }

        // Set the image only when needed (identity check on cached singleton).
        if imageView.image !== Self.chevronImage {
            imageView.image = Self.chevronImage
        }

        // Apply the rotation only when the expanded state has actually changed.
        guard lastAppliedIsExpanded != isExpanded else { return }
        lastAppliedIsExpanded = isExpanded

        let target: CGAffineTransform = isExpanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        UIView.performWithoutAnimation {
            imageView.transform = target
        }
    }

    @IBAction func favourite(_ sender: UIButton) {
        sender.isSelected.toggle()
        updateFavouriteAppearance()
        self.delegate?.favouriteButtonTappedInCell(self)
    }

    @IBAction func connect(_ sender: SILBrowserButton) {
        self.delegate?.connectButtonTappedInCell(self)
    }

    private func setAppearanceForConnectButton(connected : Bool, connectable: Bool) {
        let targetHidden = !connectable
        if connectButton.isHidden != targetHidden {
            connectButton.isHidden = targetHidden
        }

        let targetTitle = !connected ? "Connect" : "Disconnect"
        if connectButton.title(for: .normal) != targetTitle {
            connectButton.setTitle(targetTitle, for: .normal)
        }

        let redColor = UIColor(named: "sil_siliconLabsRedColor") ?? .systemRed

        if connectButton.backgroundColor != .white {
            connectButton.backgroundColor = .white
        }
        if connectButton.titleColor(for: .normal) != redColor {
            connectButton.setTitleColor(redColor, for: .normal)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if connectButton.layer.borderWidth != 1.0 {
            connectButton.layer.borderWidth = 1.0
        }
        let targetCGColor = redColor.cgColor
        if connectButton.layer.borderColor == nil || !CFEqual(connectButton.layer.borderColor!, targetCGColor) {
            connectButton.layer.borderColor = targetCGColor
        }
        CATransaction.commit()
    }

    func configure() {
        guard let discoveredPeripheral = viewModel?.discoveredPeripheral else { return }

        configureLabels(discoveredPeripheral)
        configureButtons(discoveredPeripheral)
        configureExpandedArrow(viewModel?.isExpanded ?? false)
        configureConnectingIndicator()
    }

    fileprivate func configureConnectingIndicator() {
        let shouldShow = viewModel?.isConnecting == true
        if connectingIndicator.isHidden == shouldShow {
            connectingIndicator.isHidden = !shouldShow
        }
        if shouldShow {
            if !connectingIndicator.isAnimating { connectingIndicator.startAnimating() }
        } else {
            if connectingIndicator.isAnimating { connectingIndicator.stopAnimating() }
        }
    }

    private func setTextIfChanged(_ label: UILabel, _ value: String?) {
        if label.text != value {
            label.text = value
        }
    }

    fileprivate func configureLabels(_ discoveredPeripheral: SILDiscoveredPeripheral) {
        let deviceName = discoveredPeripheral.advertisedLocalName
        let advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval * 1000

        setTextIfChanged(advertisingIntervalLabel, "\(advertisingIntervalsInMS.rounded()) ms")
        setTextIfChanged(rssiLabel, discoveredPeripheral.rssiDescription())
        setTextIfChanged(beaconLabel, discoveredPeripheral.beacon.name)
        setTextIfChanged(title, deviceName?.isEmpty == false ? deviceName : DefaultDeviceName)
        setTextIfChanged(connectableLabel,
                         discoveredPeripheral.isConnectable ? SILDiscoveredPeripheralConnectableDevice : SILDiscoveredPeripheralNonConnectableDevice)
    }

    fileprivate func configureButtons(_ discoveredPeripheral: SILDiscoveredPeripheral) {
        let isConnected = SILBrowserConnectionsViewModel.sharedInstance().isConnectedPeripheral(discoveredPeripheral.peripheral)
        if let favBtn = favouritesButton, favBtn.isSelected != discoveredPeripheral.isFavourite {
            favBtn.isSelected = discoveredPeripheral.isFavourite
        }
        updateFavouriteAppearance()
        setAppearanceForConnectButton(connected: isConnected, connectable: discoveredPeripheral.isConnectable && !discoveredPeripheral.hasTimedOut)
    }
}
