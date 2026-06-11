import UIKit

// MARK: - Theme Enum

@objc enum Theme: Int {
    case blue = 0
    case red  = 1
}

// MARK: - ThemePalette

@objcMembers
final class ThemePalette: NSObject {

    let primaryBrand: UIColor
    let navigationPrimary: UIColor
    let accent: UIColor
    let strongAccent: UIColor
    let lightAccent: UIColor

    let primaryText: UIColor
    let subtleText: UIColor
    let masalaText: UIColor
    let masala50pcText: UIColor

    let background: UIColor
    let secondaryBackground: UIColor
    let cardBackground: UIColor
    let disableCardBackground: UIColor
    let bgWhite: UIColor
    let bgGrey: UIColor

    let lineGrey: UIColor
    let lightGrey: UIColor
    let refreshGrey: UIColor
    let silver: UIColor
    let silverChalice: UIColor
    let boulder: UIColor

    let success: UIColor
    let warning: UIColor

    init(primaryBrand: UIColor,
         navigationPrimary: UIColor,
         accent: UIColor,
         strongAccent: UIColor,
         lightAccent: UIColor,
         primaryText: UIColor,
         subtleText: UIColor,
         masalaText: UIColor,
         masala50pcText: UIColor,
         background: UIColor,
         secondaryBackground: UIColor,
         cardBackground: UIColor,
         disableCardBackground: UIColor,
         bgWhite: UIColor,
         bgGrey: UIColor,
         lineGrey: UIColor,
         lightGrey: UIColor,
         refreshGrey: UIColor,
         silver: UIColor,
         silverChalice: UIColor,
         boulder: UIColor,
         success: UIColor,
         warning: UIColor) {
        self.primaryBrand        = primaryBrand
        self.navigationPrimary   = navigationPrimary
        self.accent              = accent
        self.strongAccent        = strongAccent
        self.lightAccent         = lightAccent
        self.primaryText         = primaryText
        self.subtleText          = subtleText
        self.masalaText          = masalaText
        self.masala50pcText      = masala50pcText
        self.background          = background
        self.secondaryBackground = secondaryBackground
        self.cardBackground      = cardBackground
        self.disableCardBackground = disableCardBackground
        self.bgWhite             = bgWhite
        self.bgGrey              = bgGrey
        self.lineGrey            = lineGrey
        self.lightGrey           = lightGrey
        self.refreshGrey         = refreshGrey
        self.silver              = silver
        self.silverChalice       = silverChalice
        self.boulder             = boulder
        self.success             = success
        self.warning             = warning
        super.init()
    }
}

// MARK: - ThemeManager

@objcMembers
final class ThemeManager: NSObject {

    static let shared = ThemeManager()

    static let didChangeNotification = Notification.Name("ThemeManager.didChange")

    private(set) var current: Theme = .blue
    private(set) var palette: ThemePalette

    private override init() {
        palette = Self.makePalette(for: .blue)
        super.init()
    }

    func apply(theme: Theme) {
        current = theme
        palette = Self.makePalette(for: theme)
        applyGlobalAppearances()
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    // MARK: - Palette Factory

    private static func makePalette(for theme: Theme) -> ThemePalette {
        func asset(_ name: String, fallback: UIColor) -> UIColor {
            UIColor(named: name) ?? fallback
        }

        let primaryText         = asset("sil_primaryTextColor",         fallback: .label)
        let subtleText          = asset("sil_subtitleTextColor",          fallback: .secondaryLabel)
        let masalaText          = asset("sil_masalaColor",              fallback: .darkGray)
        let masala50pcText      = asset("sil_masala50pcColor",          fallback: .gray)
        let background          = asset("sil_backgroundColor",          fallback: .systemBackground)
        let secondaryBackground = asset("sil_secondaryBackgroundColor", fallback: .secondarySystemBackground)
        let cardBackground        = asset("sil_cardBackgroundColor",   fallback: .systemBackground)
        let disableCardBackground = asset("sil_disableCardBgColor",    fallback: .systemGray6)
        let bgWhite             = asset("sil_bgWhiteColor",             fallback: .white)
        let bgGrey              = asset("sil_bgGreyColor",              fallback: .systemGray6)
        let lineGrey            = asset("sil_lineGreyColor",            fallback: .separator)
        let lightGrey           = asset("sil_lightGreyColor",           fallback: .systemGray5)
        let refreshGrey         = asset("sil_refreshGreyColor",         fallback: .systemGray4)
        let silver              = asset("sil_silverColor",              fallback: .systemGray3)
        let silverChalice       = asset("sil_silverChaliceColor",       fallback: .systemGray2)
        let boulder             = asset("sil_boulderColor",             fallback: .systemGray)
        let success             = asset("sil_regularGreenColor",        fallback: .systemGreen)
        let warning             = asset("sil_yellowColor",              fallback: .systemYellow)
        let navigationPrimary   = asset("sil_navigationPrimaryColor",   fallback: UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1.0))

        switch theme {
        case .blue:
            let brand  = asset("sil_regularBlueColor", fallback: .systemBlue)
            let strong = asset("sil_strongBlueColor",  fallback: .systemBlue)
            let light  = asset("sil_lightBlueColor",   fallback: .systemBlue.withAlphaComponent(0.3))
            return ThemePalette(
                primaryBrand: brand, navigationPrimary: navigationPrimary, accent: brand, strongAccent: strong, lightAccent: light,
                primaryText: primaryText, subtleText: subtleText, masalaText: masalaText, masala50pcText: masala50pcText,
                background: background, secondaryBackground: secondaryBackground,
                cardBackground: cardBackground, disableCardBackground: disableCardBackground,
                bgWhite: bgWhite, bgGrey: bgGrey,
                lineGrey: lineGrey, lightGrey: lightGrey, refreshGrey: refreshGrey,
                silver: silver, silverChalice: silverChalice, boulder: boulder,
                success: success, warning: warning)

        case .red:
            let brand  = asset("sil_siliconLabsRedColor", fallback: .systemRed)
            let strong = brand
            let light  = brand.withAlphaComponent(0.15)
            return ThemePalette(
                primaryBrand: brand, navigationPrimary: navigationPrimary, accent: brand, strongAccent: strong, lightAccent: light,
                primaryText: primaryText, subtleText: subtleText, masalaText: masalaText, masala50pcText: masala50pcText,
                background: background, secondaryBackground: secondaryBackground,
                cardBackground: cardBackground, disableCardBackground: disableCardBackground,
                bgWhite: bgWhite, bgGrey: bgGrey,
                lineGrey: lineGrey, lightGrey: lightGrey, refreshGrey: refreshGrey,
                silver: silver, silverChalice: silverChalice, boulder: boulder,
                success: success, warning: warning)
        }
    }

    // MARK: - Helpers

    private static func allNavigationControllers(from vc: UIViewController) -> [UINavigationController] {
        var result = [UINavigationController]()
        if let nav = vc as? UINavigationController {
            result.append(nav)
        }
        if let tab = vc as? UITabBarController {
            for child in tab.viewControllers ?? [] {
                result.append(contentsOf: allNavigationControllers(from: child))
            }
        }
        for child in vc.children {
            result.append(contentsOf: allNavigationControllers(from: child))
        }
        if let presented = vc.presentedViewController {
            result.append(contentsOf: allNavigationControllers(from: presented))
        }
        return result
    }

    // MARK: - Global UIKit Appearances

    private func applyGlobalAppearances() {
        let brand = palette.primaryBrand
        let navColor = palette.navigationPrimary

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = navColor
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.stolzlMedium(size: 17.0) as Any
        ]
        
        // Add red bottom line to navigation bar
        navAppearance.shadowColor = brand
        
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .white

        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // Add red top line to tab bar
        tabBarAppearance.shadowColor = brand
        
        let itemAppearance = tabBarAppearance.stackedLayoutAppearance
        itemAppearance.selected.iconColor = brand
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: brand]
        itemAppearance.normal.iconColor = .systemGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = brand
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }

        UITextField.appearance().tintColor = brand

        UISwitch.appearance().onTintColor = brand

        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first {
            window.tintColor = brand
            if let rootVC = window.rootViewController {
                for child in Self.allNavigationControllers(from: rootVC) {
                    child.navigationBar.tintColor = .white
                }
            }
        }
    }
}
