import SwiftData
import SwiftUI

@main
struct StudentPortfolioApp: App {
    @AppStorage("selectedTheme") private var selectedTheme = "system"

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(for: [
            Student.self,
            Achievement.self,
            Project.self,
            Certificate.self,
            Semester.self,
            Subject.self
        ])
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
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Query private var students: [Student]
    @Query private var achievements: [Achievement]
    @Query private var projects: [Project]
    @Query private var certificates: [Certificate]
    @Query private var semesters: [Semester]

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            PersistenceController.seedIfNeeded(
                modelContext: modelContext,
                students: students,
                achievements: achievements,
                projects: projects,
                certificates: certificates,
                semesters: semesters
            )
        }
    }
}
