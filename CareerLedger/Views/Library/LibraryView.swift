import SwiftData
import SwiftUI

enum LibraryTab: String, CaseIterable, Identifiable {
    case certificates = "Certificates"
    case projects = "Projects"
    case academics = "Academics"
    case achievements = "Honors"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .certificates: return "doc.text.fill"
        case .projects: return "folder.fill"
        case .academics: return "graduationcap.fill"
        case .achievements: return "trophy.fill"
        }
    }
}

struct LibraryView: View {
    @State private var selectedTab: LibraryTab = .certificates
    @Query private var certificates: [Certificate]
    @Query private var projects: [Project]
    @Query private var semesters: [Semester]
    @Query private var achievements: [Achievement]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Top custom segmented picker
            HStack(spacing: 6) {
                ForEach(LibraryTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))

                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))

                            Text("\(count(for: tab))")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    isSelected
                                        ? Color.white.opacity(0.25)
                                        : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                )
                                .clipShape(Capsule())
                        }
                        .foregroundStyle(
                            isSelected
                                ? (colorScheme == .dark ? Color.white : Color(red: 0.22, green: 0.12, blue: 0.50))
                                : (colorScheme == .dark ? Color.gray : Color(red: 0.45, green: 0.45, blue: 0.52))
                        )
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            colorScheme == .dark
                                                ? Color(red: 0.25, green: 0.22, blue: 0.40)
                                                : Color(red: 0.90, green: 0.85, blue: 0.98)
                                        )
                                        .shadow(color: Color.purple.opacity(0.12), radius: 4, y: 1)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.clear)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color.white)

            Divider()

            // Selected Sub-View
            Group {
                switch selectedTab {
                case .certificates:
                    CertificatesView()
                case .projects:
                    ProjectsView()
                case .academics:
                    AcademicsView()
                case .achievements:
                    AchievementsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func count(for tab: LibraryTab) -> Int {
        switch tab {
        case .certificates: return certificates.count
        case .projects: return projects.count
        case .academics: return semesters.count
        case .achievements: return achievements.count
        }
    }
}
