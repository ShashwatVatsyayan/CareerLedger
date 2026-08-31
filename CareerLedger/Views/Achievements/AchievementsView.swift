import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @State private var showingAddAchievement = false
    @State private var editingAchievement: Achievement?
    @State private var searchText = ""
    @State private var selectedStatus: VerificationStatus?

    private var filteredAchievements: [Achievement] {
        achievements.filter { achievement in
            let matchesSearch = searchText.isEmpty ||
            achievement.title.localizedCaseInsensitiveContains(searchText) ||
            achievement.organization.localizedCaseInsensitiveContains(searchText) ||
            achievement.category.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || achievement.verificationStatus == selectedStatus
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Achievements", subtitle: "\(achievements.count) evidence-backed records")
                    filterBar

                    if filteredAchievements.isEmpty {
                        PremiumEmptyState(
                            title: "No Achievements Yet",
                            message: "Start building your verified career record with awards, competitions, leadership, and academic wins.",
                            systemImage: "trophy",
                            actionTitle: "Add Achievement",
                            action: { showingAddAchievement = true }
                        )
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementRecordCard(
                                    achievement: achievement,
                                    onEdit: { editingAchievement = achievement },
                                    onDelete: { deleteAchievement(achievement) }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search achievements")
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: filteredAchievements.count)
            .navigationTitle("Achievements")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddAchievement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            .sheet(isPresented: $showingAddAchievement) {
                AddAchievementView()
            }
            .sheet(item: $editingAchievement) { achievement in
                AddAchievementView(achievement: achievement)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(VerificationStatus.allCases) { status in
                    FilterChip(title: status.displayName, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
        }
    }

    private func deleteAchievement(_ achievement: Achievement) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            modelContext.delete(achievement)
        }
    }
}

struct AchievementRecordCard: View {
    let achievement: Achievement
    var isPublic: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.orange.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(achievement.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(achievement.organization)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(achievement.category) | \(achievement.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VerificationBadge(status: achievement.verificationStatus)
                    }

                    Spacer()

                    if !isPublic {
                        Menu {
                            Button("Edit", systemImage: "pencil") {
                                onEdit?()
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                onDelete?()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .frame(width: 32, height: 32)
                        }
                    }
                }

                Text(achievement.achievementDescription.isEmpty ? "No description added." : achievement.achievementDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !achievement.credentialID.isEmpty {
                    LabeledContent("Credential ID", value: achievement.credentialID)
                        .font(.caption)
                }

                EvidenceSection(items: evidenceItems)

                if !isPublic, !evidenceItems.isEmpty {
                    Button {
                        onEdit?()
                    } label: {
                        Label("View Evidence", systemImage: "arrow.up.right.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var evidenceItems: [EvidenceItem] {
        var items: [EvidenceItem] = []
        if !achievement.credentialID.isEmpty {
            items.append(EvidenceItem(title: "Credential ID", detail: achievement.credentialID, url: nil, icon: "number"))
        }
        if let url = validURL(achievement.evidenceURL) {
            items.append(EvidenceItem(title: "Evidence Link", detail: achievement.evidenceURL, url: url, icon: "doc.richtext.fill"))
        }
        return items
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Achievement.self], inMemory: true)
}
