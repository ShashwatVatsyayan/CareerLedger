import SwiftUI

struct AddAchievementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var organization: String
    @State private var category: String
    @State private var date: Date
    @State private var description: String

    private let formTitle: String
    let onSave: (Achievement) -> Void

    init(achievement: Achievement? = nil, onSave: @escaping (Achievement) -> Void) {
        _title = State(initialValue: achievement?.title ?? "")
        _organization = State(initialValue: achievement?.organization ?? "")
        _category = State(initialValue: achievement?.category ?? "Technical")
        _date = State(initialValue: achievement?.date ?? Date())
        _description = State(initialValue: achievement?.description ?? "")
        formTitle = achievement == nil ? "Add Achievement" : "Edit Achievement"
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Achievement Details") {
                    TextField("Title", text: $title)
                    TextField("Organization", text: $organization)
                    Picker("Category", selection: $category) {
                        Text("Technical").tag("Technical")
                        Text("Academic").tag("Academic")
                        Text("Leadership").tag("Leadership")
                        Text("Sports").tag("Sports")
                        Text("Cultural").tag("Cultural")
                        Text("Other").tag("Other")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
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
                        let achievement = Achievement(
                            title: title,
                            organization: organization,
                            date: date,
                            category: category,
                            description: description
                        )
                        onSave(achievement)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddAchievementView { _ in }
}
