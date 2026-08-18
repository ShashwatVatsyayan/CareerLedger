import SwiftUI

struct AchievementsView: View {
    @State private var achievements = sampleAchievements
    @State private var showingAddAchievement = false
    @State private var editingAchievement: Achievement?

    var body: some View {
        NavigationStack {
            List {
                ForEach(achievements) { achievement in
                    AchievementCardView(
                        achievement: achievement,
                        onEdit: { editingAchievement = achievement },
                        onDelete: { deleteAchievement(achievement) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteAchievement(achievement)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingAchievement = achievement
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.orange.opacity(0.06))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: achievements.count)
            .navigationTitle("Achievements")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddAchievement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAchievement) {
                AddAchievementView { achievement in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        achievements.append(achievement)
                    }
                }
            }
            .sheet(item: $editingAchievement) { achievement in
                AddAchievementView(achievement: achievement) { updatedAchievement in
                    updateAchievement(achievement, with: updatedAchievement)
                }
            }
        }
    }

    private func updateAchievement(_ oldAchievement: Achievement, with updatedAchievement: Achievement) {
        guard let index = achievements.firstIndex(where: { $0.id == oldAchievement.id }) else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            achievements[index] = updatedAchievement
        }
    }

    private func deleteAchievement(_ achievement: Achievement) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            achievements.removeAll { $0.id == achievement.id }
        }
    }
}

private struct AchievementCardView: View {
    let achievement: Achievement
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.orange.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.organization)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(achievement.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14))
                    .clipShape(Capsule())
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    AchievementsView()
}
