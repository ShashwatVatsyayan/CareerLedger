import SwiftData
import SwiftUI

@main
struct StudentPortfolioApp: App {
    @AppStorage("selectedTheme") private var selectedTheme = "light"
    let container: ModelContainer

    init() {
        AppFont.registerFonts()
        ThemeManager.applyTheme(UserDefaults.standard.string(forKey: "selectedTheme") ?? "light")
        do {
            let schema = Schema([
                Student.self,
                Achievement.self,
                Project.self,
                Certificate.self,
                Semester.self,
                Subject.self,
                RoutineTask.self
            ])
            let config = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [config])
            PersistenceController.seedIfNeeded(modelContext: container.mainContext)
            self.container = container
        } catch {
            print("Notice: Existing store migration fallback triggered: \(error)")
            do {
                let schema = Schema([
                    Student.self,
                    Achievement.self,
                    Project.self,
                    Certificate.self,
                    Semester.self,
                    Subject.self,
                    RoutineTask.self
                ])
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                PersistenceController.seedIfNeeded(modelContext: container.mainContext)
                self.container = container
            } catch {
                fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .applyAppTheme()
        }
        .modelContainer(container)
    }
}

private struct AppRootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("selectedTheme") private var selectedTheme = "light"

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            if CommandLine.arguments.contains("-testDashboard") {
                isLoggedIn = true
            } else if SupabaseManager.shared.currentSession == nil {
                // Ensure no fake session persists without Supabase auth
                isLoggedIn = false
            }
            ThemeManager.applyTheme(selectedTheme)
        }
        .onChange(of: selectedTheme) { _, newTheme in
            ThemeManager.applyTheme(newTheme)
        }
        .applyAppTheme()
    }
}
