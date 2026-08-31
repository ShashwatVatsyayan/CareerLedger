import SwiftData
import SwiftUI

struct AddAchievementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var organization: String
    @State private var category: String
    @State private var date: Date
    @State private var description: String
    @State private var credentialID: String
    @State private var evidenceURL: String
    @State private var verificationStatus: VerificationStatus
    @State private var errorMessage: String?

    private let achievement: Achievement?
    private let formTitle: String

    init(achievement: Achievement? = nil) {
        self.achievement = achievement
        _title = State(initialValue: achievement?.title ?? "")
        _organization = State(initialValue: achievement?.organization ?? "")
        _category = State(initialValue: achievement?.category ?? "Technical")
        _date = State(initialValue: achievement?.date ?? Date())
        _description = State(initialValue: achievement?.achievementDescription ?? "")
        _credentialID = State(initialValue: achievement?.credentialID ?? "")
        _evidenceURL = State(initialValue: achievement?.evidenceURL ?? "")
        _verificationStatus = State(initialValue: achievement?.verificationStatus ?? .selfReported)
        formTitle = achievement == nil ? "Add Achievement" : "Edit Achievement"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Achievement Details") {
                    TextField("Achievement Title", text: $title)
                    TextField("Organization", text: $organization)
                    Picker("Category", selection: $category) {
                        ForEach(["Technical", "Academic", "Leadership", "Sports", "Cultural", "Other"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Evidence") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                    TextField("Credential ID", text: $credentialID)
                    TextField("Evidence URL", text: $evidenceURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    Picker("Verification Status", selection: $verificationStatus) {
                        ForEach(VerificationStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    Text("Issuer Verified is reserved for demo/sample records until real issuer validation is connected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    Button("Save Achievement") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrganization = organization.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedOrganization.isEmpty else {
            errorMessage = "Title and organization are required."
            return
        }

        if let achievement {
            achievement.title = trimmedTitle
            achievement.organization = trimmedOrganization
            achievement.category = category
            achievement.date = date
            achievement.achievementDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            achievement.credentialID = credentialID.trimmingCharacters(in: .whitespacesAndNewlines)
            achievement.evidenceURL = evidenceURL.trimmingCharacters(in: .whitespacesAndNewlines)
            achievement.verificationStatus = verificationStatus
        } else {
            modelContext.insert(Achievement(
                title: trimmedTitle,
                organization: trimmedOrganization,
                date: date,
                category: category,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                credentialID: credentialID.trimmingCharacters(in: .whitespacesAndNewlines),
                evidenceURL: evidenceURL.trimmingCharacters(in: .whitespacesAndNewlines),
                verificationStatus: verificationStatus
            ))
        }

        dismiss()
    }
}

#Preview {
    AddAchievementView()
        .modelContainer(for: [Achievement.self], inMemory: true)
}
