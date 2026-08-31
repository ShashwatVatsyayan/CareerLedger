import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case academics = "Academics"
    case projects = "Projects"
    case achievements = "Achievements"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .academics:
            return "graduationcap.fill"
        case .projects:
            return "folder.fill"
        case .achievements:
            return "trophy.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selection: AppSection = .dashboard
    @Query private var semesters: [Semester]
    @Query private var projects: [Project]
    @Query private var achievements: [Achievement]
    @Query private var certificates: [Certificate]

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                HStack {
                    Label(section.rawValue, systemImage: section.icon)
                    Spacer()
                    if let badge = badgeCount(for: section) {
                        Text("\(badge)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.14))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                .tag(section)
            }
            .navigationTitle("Career Ledger")
            .listStyle(.sidebar)
        } detail: {
            selectedView
                .frame(minWidth: 550)
        }
        .frame(minWidth: 880, minHeight: 580)
        #else
        TabView(selection: $selection) {
            ForEach(AppSection.allCases) { section in
                selectedView(for: section)
                    .tabItem {
                        Label(section.rawValue == "Dashboard" ? "Home" : section.rawValue, systemImage: section.icon)
                    }
                    .tag(section)
            }
        }
        #endif
    }

    private func badgeCount(for section: AppSection) -> Int? {
        switch section {
        case .academics:
            return semesters.isEmpty ? nil : semesters.count
        case .projects:
            return projects.isEmpty ? nil : projects.count
        case .achievements:
            return achievements.isEmpty ? nil : achievements.count
        default:
            return nil
        }
    }

    @ViewBuilder
    private var selectedView: some View {
        selectedView(for: selection)
    }

    @ViewBuilder
    private func selectedView(for section: AppSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView()
        case .academics:
            AcademicsView()
        case .projects:
            ProjectsView()
        case .achievements:
            AchievementsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
