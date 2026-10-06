import CoreText
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum AppFont {
    public static let playfairFamilyName = "Playfair Display"
    public static let playfairPostScriptName = "PlayfairDisplay-Regular"

    public static func registerFonts() {
        if let fontURL = Bundle.main.url(forResource: "PlayfairDisplay", withExtension: "ttf") {
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
        }

        #if os(iOS)
        configureNavigationBarAppearance()
        #endif
    }

    #if os(iOS)
    public static func configureNavigationBarAppearance() {
        let largeFont = uiFont(size: 34, weight: .bold)
        let inlineFont = uiFont(size: 19, weight: .bold)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .font: largeFont
        ]
        appearance.titleTextAttributes = [
            .font: inlineFont
        ]

        let opaqueAppearance = UINavigationBarAppearance()
        opaqueAppearance.configureWithDefaultBackground()
        opaqueAppearance.largeTitleTextAttributes = [
            .font: largeFont
        ]
        opaqueAppearance.titleTextAttributes = [
            .font: inlineFont
        ]

        UINavigationBar.appearance().standardAppearance = opaqueAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = opaqueAppearance
    }

    public static func uiFont(size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        if let font = UIFont(name: playfairFamilyName, size: size) {
            return font
        }
        if let font = UIFont(name: playfairPostScriptName, size: size) {
            return font
        }
        let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
    #endif

    public static func font(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        #if os(iOS)
        let isAvailable = UIFont.familyNames.contains(playfairFamilyName) ||
                          !UIFont.fontNames(forFamilyName: playfairFamilyName).isEmpty ||
                          UIFont(name: playfairFamilyName, size: size) != nil ||
                          UIFont(name: playfairPostScriptName, size: size) != nil
        if isAvailable {
            return Font.custom(playfairFamilyName, size: size).weight(weight)
        } else {
            return Font.system(size: size, weight: weight, design: .serif)
        }
        #else
        return Font.custom(playfairFamilyName, size: size).weight(weight)
        #endif
    }
}

public extension Font {
    static func playfair(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        AppFont.font(size: size, weight: weight)
    }
}
