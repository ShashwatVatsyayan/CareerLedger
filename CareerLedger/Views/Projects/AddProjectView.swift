import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var technologies: String
    @State private var githubURL: String
    @State private var demoURL: String

    private let formTitle: String
    let onSave: (Project) -> Void

    init(project: Project? = nil, onSave: @escaping (Project) -> Void) {
        _name = State(initialValue: project?.name ?? "")
        _description = State(initialValue: project?.description ?? "")
        _technologies = State(initialValue: project?.technologies ?? "")
        _githubURL = State(initialValue: project?.githubURL ?? "")
        _demoURL = State(initialValue: project?.demoURL ?? "")
        formTitle = project == nil ? "Add Project" : "Edit Project"
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project name", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    TextField("Technologies", text: $technologies)
                    TextField("GitHub URL", text: $githubURL)
                    TextField("Demo URL", text: $demoURL)
                }
            }
            .navigationTitle(formTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let project = Project(
                            name: name,
                            description: description,
                            technologies: technologies,
                            githubURL: githubURL,
                            demoURL: demoURL
                        )
                        onSave(project)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddProjectView { _ in }
}
