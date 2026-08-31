import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case academics = "Academics"
    case achievements = "Achievements"
    case projects = "Projects"
    case certificates = "Certificates"
    case profile = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .academics:
            return "graduationcap.fill"
        case .achievements:
            return "trophy.fill"
        case .projects:
            return "folder.fill"
        case .certificates:
            return "doc.text.fill"
        case .profile:
            return "person.fill"
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
        case .achievements:
            AchievementsView()
        case .projects:
            ProjectsView()
        case .certificates:
            CertificatesView()
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
