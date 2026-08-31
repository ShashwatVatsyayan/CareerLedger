import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case academics = "Academics"
    case projects = "Projects"
    case achievements = "Achievements"
    case profile = "Profile"
    case more = "More"

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
        case .profile:
            return "person.crop.circle.fill"
        case .more:
            return "ellipsis.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selection: AppSection = .dashboard

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Career Ledger")
        } detail: {
            selectedView
        }
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
        case .profile:
            ProfileView()
        case .more:
            MoreView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
