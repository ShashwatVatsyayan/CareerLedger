import SwiftUI

@main
struct StudentPortfolioApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @StateObject private var store = PortfolioStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    MainTabView()
                        .environmentObject(store)
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
