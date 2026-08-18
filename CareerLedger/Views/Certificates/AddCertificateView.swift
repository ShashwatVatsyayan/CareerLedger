import SwiftUI

struct AddCertificateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var organization: String
    @State private var date: Date
    @State private var credentialID: String

    private let formTitle: String
    let onSave: (Certificate) -> Void

    init(certificate: Certificate? = nil, onSave: @escaping (Certificate) -> Void) {
        _title = State(initialValue: certificate?.title ?? "")
        _organization = State(initialValue: certificate?.organization ?? "")
        _date = State(initialValue: certificate?.date ?? Date())
        _credentialID = State(initialValue: certificate?.credentialID ?? "")
        formTitle = certificate == nil ? "Add Certificate" : "Edit Certificate"
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Certificate") {
                    TextField("Certificate title", text: $title)
                    TextField("Issuing organization", text: $organization)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Credential ID", text: $credentialID)
                }

                Section("File") {
                    Text("Certificate file upload will be added in the next version.")
                        .foregroundStyle(.secondary)
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
                        let certificate = Certificate(
                            title: title,
                            organization: organization,
                            date: date,
                            credentialID: credentialID
                        )
                        onSave(certificate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddCertificateView { _ in }
}
