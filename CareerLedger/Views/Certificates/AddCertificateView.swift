import SwiftData
import SwiftUI

struct AddCertificateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var issuer: String
    @State private var issueDate: Date
    @State private var credentialID: String
    @State private var verificationURL: String
    @State private var verificationStatus: VerificationStatus
    @State private var errorMessage: String?

    private let certificate: Certificate?
    private let formTitle: String

    init(certificate: Certificate? = nil) {
        self.certificate = certificate
        _title = State(initialValue: certificate?.title ?? "")
        _issuer = State(initialValue: certificate?.issuer ?? "")
        _issueDate = State(initialValue: certificate?.issueDate ?? Date())
        _credentialID = State(initialValue: certificate?.credentialID ?? "")
        _verificationURL = State(initialValue: certificate?.verificationURL ?? "")
        _verificationStatus = State(initialValue: certificate?.verificationStatus ?? .selfReported)
        formTitle = certificate == nil ? "Add Certificate" : "Edit Certificate"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Certificate") {
                    TextField("Certificate Title", text: $title)
                    TextField("Issuer", text: $issuer)
                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    TextField("Credential ID", text: $credentialID)
                }

                Section("Verification") {
                    TextField("Verification URL", text: $verificationURL)
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
                    Button("Save Certificate") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedIssuer.isEmpty else {
            errorMessage = "Title and issuer are required."
            return
        }

        if let certificate {
            certificate.title = trimmedTitle
            certificate.issuer = trimmedIssuer
            certificate.issueDate = issueDate
            certificate.credentialID = credentialID.trimmingCharacters(in: .whitespacesAndNewlines)
            certificate.verificationURL = verificationURL.trimmingCharacters(in: .whitespacesAndNewlines)
            certificate.verificationStatus = verificationStatus
        } else {
            modelContext.insert(Certificate(
                title: trimmedTitle,
                issuer: trimmedIssuer,
                issueDate: issueDate,
                credentialID: credentialID.trimmingCharacters(in: .whitespacesAndNewlines),
                verificationURL: verificationURL.trimmingCharacters(in: .whitespacesAndNewlines),
                verificationStatus: verificationStatus
            ))
        }

        dismiss()
    }
}

#Preview {
    AddCertificateView()
        .modelContainer(for: [Certificate.self], inMemory: true)
}
