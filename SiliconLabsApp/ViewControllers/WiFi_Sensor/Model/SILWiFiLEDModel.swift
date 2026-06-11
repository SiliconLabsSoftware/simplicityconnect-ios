//
//  SILWiFiLEDModel.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 27/06/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import Foundation
enum LedImage {
    static let ledOnImage = UIImage(named: "bulb_on_tint")
    static let ledOffImage = UIImage(named: "blub_off_tint")
    static let blubOffTint = UIImage(named: "blub_off_tint")
}
enum LedType: String {
    case ledOn = "ledOn"
    case ledOff = "ledOff"
    case redOn = "redOn"
    case greenOn = "greenOn"
    case blueOn = "blueOn"
    case redOff = "redOff"
    case greenOff = "greenOff"
    case blueOff = "blueOff"
    case redGreenOn = "redGreenOn"
    case redBlueOn = "redBlueOn"
    case greenBuleOn = "greenBuleOn"
}
enum LedStatus: String {
    case ledOnState = "on"
    case ledOffState = "off"
}
enum LedColorType: String {
    case redType = "red"
    case greenType = "green"
    case blueType = "blue"
}
