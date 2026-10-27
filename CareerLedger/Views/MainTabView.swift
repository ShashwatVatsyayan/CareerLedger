import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case academics = "Academics"
    case projects = "Projects"
    case achievements = "Achievements"
    case profile = "Profile"

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
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: AppSection = .dashboard
    @Namespace private var tabAnimationNamespace
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

            // Frosted ambient blur dock covering the bottom area & safe area below the tab bar
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        LinearGradient(
                            stops: colorScheme == .dark
                                ? [
                                    .init(color: Color.clear, location: 0.0),
                                    .init(color: Color(red: 0.06, green: 0.06, blue: 0.09).opacity(0.70), location: 0.28),
                                    .init(color: Color(red: 0.03, green: 0.03, blue: 0.05).opacity(0.95), location: 0.72),
                                    .init(color: Color(red: 0.02, green: 0.02, blue: 0.03), location: 1.0)
                                ]
                                : [
                                    .init(color: Color.clear, location: 0.0),
                                    .init(color: Color.white.opacity(0.55), location: 0.28),
                                    .init(color: Color.white.opacity(0.90), location: 0.72),
                                    .init(color: Color.white, location: 1.0)
                                ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.85), location: 0.35),
                                .init(color: .black, location: 0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 130)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)

            customFloatingBar
        }
        .ignoresSafeArea(.keyboard)
        .applyAppTheme()
        #endif
    }

    #if !os(macOS)
    private var customFloatingBar: some View {
        HStack(spacing: 4) {
            ForEach(AppSection.allCases) { section in
                let isSelected = selection == section

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selection = section
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: section.icon)
                                .font(.system(size: isSelected ? 19 : 17, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(
                                    isSelected
                                        ? (colorScheme == .dark
                                            ? LinearGradient(
                                                colors: [
                                                    Color.white,
                                                    Color(red: 0.65, green: 0.82, blue: 1.0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: [
                                                    Color.blue,
                                                    Color(red: 0.15, green: 0.35, blue: 0.85)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ))
                                        : (colorScheme == .dark
                                            ? LinearGradient(
                                                colors: [
                                                    Color(red: 0.58, green: 0.60, blue: 0.66),
                                                    Color(red: 0.42, green: 0.44, blue: 0.50)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: [
                                                    Color(red: 0.45, green: 0.47, blue: 0.53),
                                                    Color(red: 0.38, green: 0.40, blue: 0.45)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ))
                                )
                                .frame(height: 22)
                                .shadow(
                                    color: isSelected
                                        ? (colorScheme == .dark
                                            ? Color(red: 0.3, green: 0.55, blue: 1.0).opacity(0.6)
                                            : Color.blue.opacity(0.35))
                                        : Color.clear,
                                    radius: 6,
                                    y: 1
                                )

                            if let badge = badgeCount(for: section) {
                                Text("\(badge)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -4)
                            }
                        }

                        Text(section.displayName)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? (colorScheme == .dark ? Color.white : Color.blue)
                                    : (colorScheme == .dark ? Color(red: 0.58, green: 0.60, blue: 0.66) : Color(red: 0.45, green: 0.47, blue: 0.53))
                            )
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        colorScheme == .dark
                                            ? LinearGradient(
                                                colors: [
                                                    Color(red: 0.22, green: 0.42, blue: 0.95).opacity(0.32),
                                                    Color(red: 0.12, green: 0.22, blue: 0.55).opacity(0.18)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.18),
                                                    Color.blue.opacity(0.08)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(
                                                colorScheme == .dark
                                                    ? LinearGradient(
                                                        colors: [
                                                            Color(red: 0.45, green: 0.70, blue: 1.0).opacity(0.45),
                                                            Color.clear
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                    : LinearGradient(
                                                        colors: [
                                                            Color.blue.opacity(0.40),
                                                            Color.blue.opacity(0.05)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ),
                                                lineWidth: 0.8
                                            )
                                    }
                                    .matchedGeometryEffect(id: "activeTabPill", in: tabAnimationNamespace)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? AnyShapeStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 0.16, green: 0.16, blue: 0.19).opacity(0.97), location: 0.0),
                                    .init(color: Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.98), location: 0.5),
                                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        : AnyShapeStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.96), location: 0.0),
                                    .init(color: Color(red: 0.95, green: 0.96, blue: 0.98).opacity(0.97), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.35)
                        : Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.08),
                                        Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.25),
                                        Color.black.opacity(0.8)
                                    ]
                                    : [
                                        Color.white,
                                        Color.white.opacity(0.6),
                                        Color(red: 0.8, green: 0.85, blue: 0.92),
                                        Color.black.opacity(0.08)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
        .animation(.easeInOut(duration: 0.35), value: colorScheme)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
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
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
