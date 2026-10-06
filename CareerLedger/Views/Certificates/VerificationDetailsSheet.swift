import SwiftUI
import SwiftData

struct VerificationDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let certificate: Certificate

    @State private var isVerifying = false
    @State private var record: CertificateVerificationRecord
    @State private var showingEvidencePreview = false

    init(certificate: Certificate) {
        self.certificate = certificate
        _record = State(initialValue: certificate.parsedVerificationRecord)
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                VStack(spacing: 20) {
                    // Status Header Card
                    statusHeaderCard

                    // Status Explanation
                    explanationCard

                    // Details Card
                    detailsCard

                    // Matched Information
                    matchedInfoCard

                    // Evidence Attachment (if present)
                    if !certificate.evidenceURL.isEmpty {
                        evidenceAttachmentCard
                    }

                    // Re-verify Action
                    reverifyButton
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Verification Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEvidencePreview) {
                EvidenceDocumentPreviewSheet(evidenceURL: certificate.evidenceURL, title: certificate.title)
            }
        }
    }

    // MARK: - Status Header Card
    private var statusHeaderCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text(certificate.verificationStatus.colorDot)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(certificate.verificationStatus.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(certificate.verificationStatus.tintColor)

                        Text(certificate.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Explanation Card
    private var explanationCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(certificate.verificationStatus.tintColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Trust & Audit Note")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(record.notes.isEmpty ? certificate.verificationStatus.detailedExplanation : record.notes)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Details Card
    private var detailsCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack {
                    Text("Verification Method")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedMethod(record.method))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Verified On")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let date = record.verifiedAt ?? certificate.verifiedAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("Pending Verification")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !certificate.verificationSource.isEmpty || !record.source.isEmpty {
                    Divider()
                    let sourceURL = record.source.isEmpty ? certificate.verificationSource : record.source
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Authoritative Source")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let valid = URL(string: sourceURL) {
                            Link(destination: valid) {
                                HStack(spacing: 6) {
                                    Image(systemName: "safari.fill")
                                        .font(.caption)
                                    Text(sourceURL)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .foregroundStyle(.blue)
                            }
                        } else {
                            Text(sourceURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Matched Information Card
    private var matchedInfoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Verification Evidence Check")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if certificate.verificationStatus == .automaticallyVerified || certificate.verificationStatus == .issuerVerified {
                    checklistRow(title: "Credential ID Verified", detail: certificate.credentialID.isEmpty ? "Direct Registry Match" : certificate.credentialID, isChecked: true)
                    checklistRow(title: "Issuer Authority Confirmed", detail: certificate.issuer, isChecked: true)
                    checklistRow(title: "Recipient Name Reconciled", detail: "Authenticated Profile", isChecked: true)
                    checklistRow(title: "Issue Date Consistency", detail: certificate.issueDate.formatted(date: .abbreviated, time: .omitted), isChecked: true)
                } else if certificate.verificationStatus == .evidenceProvided {
                    checklistRow(title: "Supporting Evidence Document", detail: "Attached on file", isChecked: true)
                    checklistRow(title: "Credential ID Provided", detail: certificate.credentialID.isEmpty ? "None" : certificate.credentialID, isChecked: !certificate.credentialID.isEmpty)
                    checklistRow(title: "Independent Issuer API / Portal", detail: "Awaiting issuer portal verification", isChecked: false)
                } else if certificate.verificationStatus == .disputed {
                    checklistRow(title: "Issuer Registry Queried", detail: "Official Portal", isChecked: true)
                    checklistRow(title: "Credential Status", detail: "Invalid, Revoked, or Nonexistent", isChecked: false, isError: true)
                } else {
                    checklistRow(title: "Self-Reported Entry", detail: "User manual entry", isChecked: true)
                    checklistRow(title: "Evidence Attached", detail: "None", isChecked: false)
                    checklistRow(title: "Online Verification", detail: "None", isChecked: false)
                }
            }
        }
    }

    // MARK: - Evidence Attachment Card
    private var evidenceAttachmentCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Supporting Evidence Attached")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Stored reference to evidence proof")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingEvidencePreview = true
                } label: {
                    Text("View Proof")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Re-verify Button
    private var reverifyButton: some View {
        Button {
            Task {
                await reverifyCredential()
            }
        } label: {
            HStack {
                if isVerifying {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Run Authoritative Verification Check")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .disabled(isVerifying)
    }

    private func checklistRow(title: String, detail: String, isChecked: Bool, isError: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.octagon.fill" : (isChecked ? "checkmark.circle.fill" : "circle"))
                .foregroundStyle(isError ? .red : (isChecked ? .green : .secondary))
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func formattedMethod(_ method: String) -> String {
        switch method {
        case "official_verification_url":
            return "Official Issuer Portal"
        case "official_api":
            return "Official Issuer API"
        case "issuer_portal":
            return "Issuer Portal"
        case "issuer_confirmation":
            return "Direct Issuer Confirmation"
        case "document_evidence":
            return "Evidence Document on File"
        case "manual_entry":
            return "Manual User Record"
        default:
            return method.isEmpty ? "Standard Evaluation" : method.capitalized
        }
    }

    private func reverifyCredential() async {
        isVerifying = true
        let userFullName = SupabaseManager.shared.currentUserFullName

        let request = CredentialVerificationRequest(
            certificateTitle: certificate.title,
            issuer: certificate.issuer,
            recipientName: userFullName,
            credentialID: certificate.credentialID,
            verificationURL: certificate.verificationURL,
            issueDate: certificate.issueDate,
            hasEvidence: !certificate.evidenceURL.isEmpty
        )

        let result = await CertificateVerificationService.shared.verifyCredential(request: request)

        withAnimation {
            certificate.verificationStatus = result.status
            certificate.verificationMethod = result.method
            certificate.verifiedAt = result.verifiedAt
            certificate.verificationSource = result.source

            let newRecord = CertificateVerificationRecord(
                status: result.status,
                method: result.method,
                verifiedAt: result.verifiedAt,
                source: result.source,
                matchedFields: result.matchedFields,
                unmatchedFields: result.unmatchedFields,
                notes: result.notes,
                authoritativeDomain: URL(string: result.source)?.host(),
                isAuthoritativeSource: result.isAuthoritative
            )
            certificate.verificationDetails = newRecord.toJSONString()
            record = newRecord
            try? modelContext.save()
            isVerifying = false
        }
    }
}

// MARK: - Evidence Document Preview Sheet
struct EvidenceDocumentPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let evidenceURL: String
    let title: String

    @State private var fileData: Data? = nil
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading evidence...")
                } else if let data = fileData {
                    if let image = UIImage(data: data) {
                        ScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .padding()
                        }
                    } else {
                        // PDF Preview
                        PDFKitRepresentedView(data: data)
                            .edgesIgnoringSafeArea(.bottom)
                    }
                } else {
                    ContentUnavailableView(
                        "Unable to Load Evidence",
                        systemImage: "doc.questionmark",
                        description: Text("Could not retrieve the evidence document from \(evidenceURL)")
                    )
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                fileData = await EvidenceStorageService.shared.loadEvidenceData(from: evidenceURL)
                isLoading = false
            }
        }
    }
}

// MARK: - PDFKit Represented View
import PDFKit

struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: data)
        }
    }
}
