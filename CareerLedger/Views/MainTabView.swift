import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case academics = "Academics"
    case projects = "Projects"
    case achievements = "Achievements"
    case profile = "Profile"
    case settings = "Settings"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dashboard:
            return "Home"
        case .academics:
            return "Academics"
        case .projects:
            return "Projects"
        case .achievements:
            return "Honors"
        case .profile:
            return "Profile"
        case .settings:
            return "Settings"
        }
    }

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
        ZStack(alignment: .bottom) {
            selectedView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            customFloatingBar
        }
        .ignoresSafeArea(.keyboard)
        #endif
    }

    #if !os(macOS)
    private var customFloatingBar: some View {
        HStack(spacing: 0) {
            ForEach(AppSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selection = section
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: section.icon)
                            .font(.system(size: selection == section ? 19 : 17, weight: selection == section ? .bold : .regular))
                            .foregroundStyle(selection == section ? Color.blue : Color.secondary)
                            .frame(height: 22)

                        Text(section.displayName)
                            .font(.system(size: 10, weight: selection == section ? .bold : .medium))
                            .foregroundStyle(selection == section ? Color.blue : Color.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
    #endif

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
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
