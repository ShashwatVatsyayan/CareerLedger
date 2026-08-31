import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @State private var showingAddProject = false
    @State private var editingProject: Project?
    @State private var searchText = ""
    @State private var selectedStatus: VerificationStatus?

    private var filteredProjects: [Project] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty ||
            project.name.localizedCaseInsensitiveContains(searchText) ||
            project.projectDescription.localizedCaseInsensitiveContains(searchText) ||
            project.technologies.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || project.verificationStatus == selectedStatus
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Projects", subtitle: "\(projects.count) stored project records")
                    filterBar

                    if filteredProjects.isEmpty {
                        PremiumEmptyState(
                            title: "No Projects Yet",
                            message: "Add projects with descriptions, technologies, GitHub links, demos, and evidence.",
                            systemImage: "folder.badge.plus",
                            actionTitle: "Add Project",
                            action: { showingAddProject = true }
                        )
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                            ForEach(filteredProjects) { project in
                                ProjectRecordCard(
                                    project: project,
                                    onEdit: { editingProject = project },
                                    onDelete: { deleteProject(project) }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search projects")
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: filteredProjects.count)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
            .sheet(item: $editingProject) { project in
                AddProjectView(project: project)
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

    private func deleteProject(_ project: Project) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            modelContext.delete(project)
            try? modelContext.save()
        }
    }
}

struct ProjectRecordCard: View {
    let project: Project
    var isPublic: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.purple.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(project.technologies.replacingOccurrences(of: ",", with: " •"))
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                        VerificationBadge(status: project.verificationStatus)
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

                Text(project.projectDescription.isEmpty ? "No description added." : project.projectDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                EvidenceSection(items: evidenceItems)

                if !isPublic {
                    Button {
                        onEdit?()
                    } label: {
                        Label("View Project", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var evidenceItems: [EvidenceItem] {
        var items: [EvidenceItem] = []
        if let url = validURL(project.githubURL) {
            items.append(EvidenceItem(title: "GitHub Repository", detail: project.githubURL, url: url, icon: "chevron.left.slash.chevron.right"))
        }
        if let url = validURL(project.demoURL) {
            items.append(EvidenceItem(title: "Demo Available", detail: project.demoURL, url: url, icon: "play.circle.fill"))
        }
        return items
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue.opacity(0.18) : Color.secondary.opacity(0.10))
                .foregroundStyle(isSelected ? .blue : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: [Project.self], inMemory: true)
}
