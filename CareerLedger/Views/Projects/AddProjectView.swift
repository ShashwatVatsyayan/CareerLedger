import SwiftData
import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String
    @State private var description: String
    @State private var technologies: String
    @State private var githubURL: String
    @State private var demoURL: String
    @State private var verificationStatus: VerificationStatus
    @State private var date: Date
    @State private var errorMessage: String?

    private let project: Project?
    private let formTitle: String

    init(project: Project? = nil) {
        self.project = project
        _name = State(initialValue: project?.name ?? "")
        _description = State(initialValue: project?.projectDescription ?? "")
        _technologies = State(initialValue: project?.technologies ?? "")
        _githubURL = State(initialValue: project?.githubURL ?? "")
        _demoURL = State(initialValue: project?.demoURL ?? "")
        _verificationStatus = State(initialValue: project?.verificationStatus ?? .selfReported)
        _date = State(initialValue: project?.date ?? Date())
        formTitle = project == nil ? "Add Project" : "Edit Project"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project Name", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                    TextField("Technologies", text: $technologies)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Links") {
                    TextField("GitHub URL", text: $githubURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Demo URL", text: $demoURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    Picker("Verification Status", selection: $verificationStatus) {
                        ForEach(VerificationStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
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
                    Button("Save Project") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Project name is required."
            return
        }

        if let project {
            project.name = trimmedName
            project.projectDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            project.technologies = technologies.trimmingCharacters(in: .whitespacesAndNewlines)
            project.githubURL = githubURL.trimmingCharacters(in: .whitespacesAndNewlines)
            project.demoURL = demoURL.trimmingCharacters(in: .whitespacesAndNewlines)
            project.verificationStatus = verificationStatus
            project.date = date
        } else {
            modelContext.insert(Project(
                name: trimmedName,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                technologies: technologies.trimmingCharacters(in: .whitespacesAndNewlines),
                githubURL: githubURL.trimmingCharacters(in: .whitespacesAndNewlines),
                demoURL: demoURL.trimmingCharacters(in: .whitespacesAndNewlines),
                verificationStatus: verificationStatus,
                date: date
            ))
        }

        dismiss()
    }
}

#Preview {
    AddProjectView()
        .modelContainer(for: [Project.self], inMemory: true)
}
