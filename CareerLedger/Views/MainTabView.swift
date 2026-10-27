import SwiftData
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case routine = "Routine"
    case discover = "Discover"
    case library = "Library"
    case profile = "Profile"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .routine:
            return "checkmark.seal.fill"
        case .discover:
            return "square.grid.2x2.fill"
        case .library:
            return "books.vertical.fill"
        case .profile:
            return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: AppSection = .routine
    @Namespace private var tabAnimationNamespace

    @Query private var tasks: [RoutineTask]
    @Query private var certificates: [Certificate]
    @Query private var projects: [Project]

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
                            .background(Color.purple.opacity(0.14))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
                .tag(section)
            }
            .navigationTitle("Career Ledger")
            .listStyle(.sidebar)
        } detail: {
            selectedView
                .frame(minWidth: 600)
        }
        .frame(minWidth: 920, minHeight: 600)
        #else
        ZStack(alignment: .bottom) {
            // Selected Screen Content
            selectedView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Modern Bottom Tab Bar matching screenshot
            customBottomTabBar
        }
        .ignoresSafeArea(.keyboard)
        .applyAppTheme()
        #endif
    }

    #if !os(macOS)
    private var customBottomTabBar: some View {
        VStack(spacing: 0) {
            // Center Dot Indicator matching screenshot
            Circle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.35) : Color(red: 0.55, green: 0.55, blue: 0.58))
                .frame(width: 14, height: 14)
                .padding(.bottom, 6)

            // Tab Buttons
            HStack(spacing: 0) {
                ForEach(AppSection.allCases) { section in
                    let isSelected = selection == section

                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                            selection = section
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: section.icon)
                                .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.white : Color(red: 0.10, green: 0.10, blue: 0.14))
                                        : (colorScheme == .dark ? Color.gray.opacity(0.6) : Color(red: 0.70, green: 0.72, blue: 0.76))
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .frame(height: 24)

                            Text(section.displayName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.white : Color(red: 0.10, green: 0.10, blue: 0.14))
                                        : (colorScheme == .dark ? Color.gray.opacity(0.6) : Color(red: 0.70, green: 0.72, blue: 0.76))
                                )
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(
            colorScheme == .dark
                ? Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.98)
                : Color.white.opacity(0.98)
        )
        .overlay(
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .frame(height: 0.8),
            alignment: .top
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.05),
            radius: 10,
            x: 0,
            y: -2
        )
    }
    #endif

    private func badgeCount(for section: AppSection) -> Int? {
        switch section {
        case .routine:
            let pending = tasks.filter { !$0.isCompleted }.count
            return pending > 0 ? pending : nil
        case .library:
            let total = certificates.count + projects.count
            return total > 0 ? total : nil
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
        case .routine:
            RoutineView()
        case .discover:
            DashboardView()
        case .library:
            LibraryView()
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [
                Student.self,
                Semester.self,
                Subject.self,
                Project.self,
                Achievement.self,
                Certificate.self,
                RoutineTask.self
            ],
            inMemory: true
        )
}
