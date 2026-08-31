import SwiftData
import SwiftUI

@main
struct StudentPortfolioApp: App {
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Student.self,
                Achievement.self,
                Project.self,
                Certificate.self,
                Semester.self,
                Subject.self
            ])
            let config = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [config])
            PersistenceController.seedIfNeeded(modelContext: container.mainContext)
            self.container = container
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)
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

private struct AppRootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("selectedTheme") private var selectedTheme = "system"

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(colorScheme)
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
