import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum ThemeManager {
    public static func colorScheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    public static func applyTheme(_ theme: String) {
        #if os(iOS)
        let style: UIUserInterfaceStyle
        switch theme {
        case "light":
            style = .light
        case "dark":
            style = .dark
        default:
            style = .unspecified
        }

        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    UIView.transition(
                        with: window,
                        duration: 0.35,
                        options: [.transitionCrossDissolve, .allowAnimatedContent],
                        animations: {
                            window.overrideUserInterfaceStyle = style
                            if let root = window.rootViewController {
                                updateViewController(root, style: style)
                            }
                        },
                        completion: nil
                    )
                }
            }
        }
        #endif
    }

    #if os(iOS)
    private static func updateViewController(_ vc: UIViewController, style: UIUserInterfaceStyle) {
        vc.overrideUserInterfaceStyle = style
        vc.setNeedsStatusBarAppearanceUpdate()
        for child in vc.children {
            updateViewController(child, style: style)
        }
        if let presented = vc.presentedViewController {
            updateViewController(presented, style: style)
        }
    }
    #endif
}

public struct AppThemeModifier: ViewModifier {
    @AppStorage("selectedTheme") private var selectedTheme = "dark"

    public init() {}

    public func body(content: Content) -> some View {
        let scheme = ThemeManager.colorScheme(for: selectedTheme)
        if let scheme {
            content
                .preferredColorScheme(scheme)
                .environment(\.colorScheme, scheme)
                .animation(.easeInOut(duration: 0.35), value: scheme)
        } else {
            content
                .preferredColorScheme(nil)
                .animation(.easeInOut(duration: 0.35), value: selectedTheme)
        }
    }
}

public extension View {
    func applyAppTheme() -> some View {
        self.modifier(AppThemeModifier())
    }
}
