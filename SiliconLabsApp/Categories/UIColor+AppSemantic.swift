import UIKit
import SwiftUI

// MARK: - UIColor Semantic Accessors (available from Swift & ObjC)

extension UIColor {

    private static var p: ThemePalette { ThemeManager.shared.palette }

    // ── Brand / Accent ──────────────────────────────────────────────
    @objc static var appPrimaryBrand: UIColor     { p.primaryBrand }
    @objc static var appNavigationPrimary: UIColor { p.navigationPrimary }
    @objc static var appAccent: UIColor           { p.accent }
    @objc static var appStrongAccent: UIColor     { p.strongAccent }
    @objc static var appLightAccent: UIColor      { p.lightAccent }

    // ── Text ────────────────────────────────────────────────────────
    @objc static var appPrimaryText: UIColor  { p.primaryText }
    @objc static var appSubtleText: UIColor   { p.subtleText }
    @objc static var appMasalaText: UIColor   { p.masalaText }
    @objc static var appMasala50pcText: UIColor { p.masala50pcText }

    // ── Backgrounds ─────────────────────────────────────────────────
    @objc static var appBackground: UIColor          { p.background }
    @objc static var appSecondaryBackground: UIColor { p.secondaryBackground }
    @objc static var appCardBackground: UIColor        { p.cardBackground }
    @objc static var appDisableCardBackground: UIColor { p.disableCardBackground }
    @objc static var appBgWhite: UIColor               { p.bgWhite }
    @objc static var appBgGrey: UIColor                { p.bgGrey }

    // ── Greys / Borders ─────────────────────────────────────────────
    @objc static var appLineGrey: UIColor       { p.lineGrey }
    @objc static var appLightGrey: UIColor      { p.lightGrey }
    @objc static var appRefreshGrey: UIColor    { p.refreshGrey }
    @objc static var appSilver: UIColor         { p.silver }
    @objc static var appSilverChalice: UIColor  { p.silverChalice }
    @objc static var appBoulder: UIColor        { p.boulder }

    // ── Semantic Status ─────────────────────────────────────────────
    @objc static var appSuccess: UIColor { p.success }
    @objc static var appWarning: UIColor { p.warning }
}

// MARK: - SwiftUI Color Adapters

extension Color {

    // ── Brand / Accent ──────────────────────────────────────────────
    static var appPrimaryBrand: Color { Color(UIColor.appPrimaryBrand) }
    static var appNavigationPrimary: Color { Color(UIColor.appNavigationPrimary) }
    static var appAccent: Color       { Color(UIColor.appAccent) }
    static var appStrongAccent: Color { Color(UIColor.appStrongAccent) }
    static var appLightAccent: Color  { Color(UIColor.appLightAccent) }

    // ── Text ────────────────────────────────────────────────────────
    static var appPrimaryText: Color  { Color(UIColor.appPrimaryText) }
    static var appSubtleText: Color   { Color(UIColor.appSubtleText) }

    // ── Backgrounds ─────────────────────────────────────────────────
    static var appBackground: Color          { Color(UIColor.appBackground) }
    static var appSecondaryBackground: Color { Color(UIColor.appSecondaryBackground) }
    static var appCardBackground: Color        { Color(UIColor.appCardBackground) }
    static var appDisableCardBackground: Color { Color(UIColor.appDisableCardBackground) }

    // ── Greys ───────────────────────────────────────────────────────
    static var appLineGrey: Color    { Color(UIColor.appLineGrey) }
    static var appLightGrey: Color   { Color(UIColor.appLightGrey) }

    // ── Status ──────────────────────────────────────────────────────
    static var appSuccess: Color { Color(UIColor.appSuccess) }
    static var appWarning: Color { Color(UIColor.appWarning) }
}
