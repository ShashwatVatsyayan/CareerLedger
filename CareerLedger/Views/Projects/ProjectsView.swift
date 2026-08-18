import SwiftUI

struct ProjectsView: View {
    @State private var projects = sampleProjects
    @State private var showingAddProject = false
    @State private var editingProject: Project?

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    ProjectCardView(
                        project: project,
                        onEdit: { editingProject = project },
                        onDelete: { deleteProject(project) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingProject = project
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.purple.opacity(0.06))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: projects.count)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView { project in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        projects.append(project)
                    }
                }
            }
            .sheet(item: $editingProject) { project in
                AddProjectView(project: project) { updatedProject in
                    updateProject(project, with: updatedProject)
                }
            }
        }
    }

    private func updateProject(_ oldProject: Project, with updatedProject: Project) {
        guard let index = projects.firstIndex(where: { $0.id == oldProject.id }) else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            projects[index] = updatedProject
        }
    }

    private func deleteProject(_ project: Project) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            projects.removeAll { $0.id == project.id }
        }
    }
}

private struct ProjectCardView: View {
    let project: Project
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.purple.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.headline)
                Text(project.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(project.technologies)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
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
    ProjectsView()
}
