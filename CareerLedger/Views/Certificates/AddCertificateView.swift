import SwiftData
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Supabase
import Auth
import PostgREST

struct AddCertificateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form fields
    @State private var title: String
    @State private var issuer: String
    @State private var issueDate: Date
    @State private var credentialID: String
    @State private var verificationURL: String
    @State private var verificationStatus: CertificateVerificationStatus
    @State private var evidenceURL: String
    @State private var verificationMethod: String
    @State private var verifiedAt: Date?
    @State private var verificationSource: String
    @State private var verificationDetails: String

    // Evidence & Extraction states
    @State private var isProcessingEvidence = false
    @State private var isVerifyingOnline = false
    @State private var evidenceFilename: String?
    @State private var extractedDetails: ExtractedCertificateDetails?
    @State private var showingExtractionReview = false
    @State private var verificationFeedbackMessage: String?
    @State private var verificationFeedbackType: FeedbackType = .info
    @State private var errorMessage: String?

    // Pickers
    @State private var showingFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    private let certificate: Certificate?
    private let formTitle: String

    enum FeedbackType {
        case success, info, warning, error
        var color: Color {
            switch self {
            case .success: return .green
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
        var icon: String {
            switch self {
            case .success: return "checkmark.seal.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }
    }

    init(certificate: Certificate? = nil) {
        self.certificate = certificate
        _title = State(initialValue: certificate?.title ?? "")
        _issuer = State(initialValue: certificate?.issuer ?? "")
        _issueDate = State(initialValue: certificate?.issueDate ?? Date())
        _credentialID = State(initialValue: certificate?.credentialID ?? "")
        _verificationURL = State(initialValue: certificate?.verificationURL ?? "")
        _verificationStatus = State(initialValue: certificate?.verificationStatus ?? .notVerified)
        _evidenceURL = State(initialValue: certificate?.evidenceURL ?? "")
        _verificationMethod = State(initialValue: certificate?.verificationMethod ?? "")
        _verifiedAt = State(initialValue: certificate?.verifiedAt)
        _verificationSource = State(initialValue: certificate?.verificationSource ?? "")
        _verificationDetails = State(initialValue: certificate?.verificationDetails ?? "")
        formTitle = certificate == nil ? "Add Certificate" : "Edit Certificate"
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Evidence Upload Section (Top recommendation)
                evidenceSection

                // MARK: - Extracted Review Banner
                if let extracted = extractedDetails, showingExtractionReview {
                    extractedReviewSection(extracted: extracted)
                }

                // MARK: - Certificate Information
                Section("Certificate Details") {
                    TextField("Certificate Title", text: $title)
                    TextField("Issuer (e.g. Google Cloud, Coursera, University)", text: $issuer)
                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    TextField("Credential ID / Number", text: $credentialID)
                }

                // MARK: - Verification Section
                verificationSection

                // MARK: - Error message
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
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
                    .disabled(isProcessingEvidence || isVerifyingOnline)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .png, .jpeg],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem: newItem)
            }
        }
    }

    // MARK: - Evidence Section
    private var evidenceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.arrow.up.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Certificate Evidence (Proof)")
                            .font(.headline)
                        Text("Upload PDF or certificate photo (PNG/JPG)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if isProcessingEvidence {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Analyzing document and reading credential details...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else if !evidenceURL.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(evidenceFilename ?? "Evidence Document Attached")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button(role: .destructive) {
                            evidenceURL = ""
                            evidenceFilename = nil
                            extractedDetails = nil
                            showingExtractionReview = false
                            if verificationStatus == .evidenceProvided {
                                verificationStatus = .notVerified
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                HStack(spacing: 12) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Choose File (PDF/Image)", systemImage: "folder")
                            .font(.footnote)
                    }
                    .buttonStyle(.bordered)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo Library", systemImage: "photo")
                            .font(.footnote)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Document Evidence")
        } footer: {
            Text("Uploading evidence preserves your proof and extracts details. Status becomes Evidence Provided unless independently verified with an official issuer.")
        }
    }

    // MARK: - Extracted Review Section
    private func extractedReviewSection(extracted: ExtractedCertificateDetails) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Extracted from Evidence")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Dismiss") {
                        showingExtractionReview = false
                    }
                    .font(.caption2)
                }

                Text("Review and apply the extracted fields to your certificate record:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !extracted.title.isEmpty {
                    extractedRow(label: "Title", value: extracted.title) {
                        title = extracted.title
                    }
                }
                if !extracted.issuer.isEmpty {
                    extractedRow(label: "Issuer", value: extracted.issuer) {
                        issuer = extracted.issuer
                    }
                }
                if !extracted.credentialID.isEmpty {
                    extractedRow(label: "Credential ID", value: extracted.credentialID) {
                        credentialID = extracted.credentialID
                    }
                }
                if !extracted.verificationURL.isEmpty {
                    extractedRow(label: "Verification URL", value: extracted.verificationURL) {
                        verificationURL = extracted.verificationURL
                    }
                }

                Button {
                    applyAllExtracted(extracted)
                } label: {
                    Text("Apply All Extracted Fields")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.vertical, 6)
        } header: {
            Text("OCR Document Scanner")
        }
    }

    private func extractedRow(label: String, value: String, onApply: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .lineLimit(2)
            }
            Spacer()
            Button("Apply", action: onApply)
                .font(.caption2)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
    }

    // MARK: - Verification Section
    private var verificationSection: some View {
        Section("Verification & Trust") {
            TextField("Official Verification URL", text: $verificationURL)
                .urlInputStyle()

            HStack {
                Text("Verification Status")
                Spacer()
                VerificationBadge(status: verificationStatus)
            }

            if let message = verificationFeedbackMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: verificationFeedbackType.icon)
                        .foregroundStyle(verificationFeedbackType.color)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(verificationFeedbackType.color)
                }
                .padding(.vertical, 4)
            }

            // Run Verification Button
            Button {
                Task {
                    await checkAuthoritativeOnlineVerification()
                }
            } label: {
                HStack {
                    if isVerifyingOnline {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking Official Verification Portal...")
                    } else {
                        Image(systemName: "checkmark.shield")
                        Text("Check Online Verification")
                            .fontWeight(.semibold)
                    }
                }
            }
            .disabled(isVerifyingOnline)
        }
    }

    // MARK: - Handlers
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else { return }
            processEvidenceData(data: data, filename: url.lastPathComponent)

        case .failure(let error):
            errorMessage = "Could not open document: \(error.localizedDescription)"
        }
    }

    private func handlePhotoSelection(newItem: PhotosPickerItem?) {
        guard let item = newItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    processEvidenceData(data: data, filename: "certificate_photo.png")
                }
            }
        }
    }

    private func processEvidenceData(data: Data, filename: String) {
        isProcessingEvidence = true
        evidenceFilename = filename

        // 1. Default to EVIDENCE_PROVIDED when supporting document is added
        // It must NOT say Verified!
        verificationStatus = .evidenceProvided

        Task {
            let certID = certificate?.id ?? UUID()
            let storedURL = await EvidenceStorageService.shared.storeEvidence(
                data: data,
                originalFilename: filename,
                mimeType: filename.lowercased().hasSuffix(".pdf") ? "application/pdf" : "image/png",
                certificateID: certID
            )

            // Extract details with Vision / PDFKit
            let extracted = await CertificateEvidenceExtractor.shared.extractDetails(from: data, filename: filename)

            await MainActor.run {
                evidenceURL = storedURL
                extractedDetails = extracted
                isProcessingEvidence = false
                showingExtractionReview = !extracted.title.isEmpty || !extracted.issuer.isEmpty || !extracted.credentialID.isEmpty

                // If user hasn't filled fields, suggest extracted ones
                if title.isEmpty && !extracted.title.isEmpty {
                    title = extracted.title
                }
                if issuer.isEmpty && !extracted.issuer.isEmpty {
                    issuer = extracted.issuer
                }
                if credentialID.isEmpty && !extracted.credentialID.isEmpty {
                    credentialID = extracted.credentialID
                }
                if verificationURL.isEmpty && !extracted.verificationURL.isEmpty {
                    verificationURL = extracted.verificationURL
                }
                if let d = extracted.issueDate {
                    issueDate = d
                }

                verificationFeedbackMessage = "Document uploaded as evidence. Status set to Evidence Provided."
                verificationFeedbackType = .info
            }
        }
    }

    private func applyAllExtracted(_ extracted: ExtractedCertificateDetails) {
        if !extracted.title.isEmpty { title = extracted.title }
        if !extracted.issuer.isEmpty { issuer = extracted.issuer }
        if !extracted.credentialID.isEmpty { credentialID = extracted.credentialID }
        if !extracted.verificationURL.isEmpty { verificationURL = extracted.verificationURL }
        if let d = extracted.issueDate { issueDate = d }
        showingExtractionReview = false
    }

    private func checkAuthoritativeOnlineVerification() async {
        isVerifyingOnline = true
        errorMessage = nil

        let userFullName = SupabaseManager.shared.currentUserFullName

        let request = CredentialVerificationRequest(
            certificateTitle: title,
            issuer: issuer,
            recipientName: userFullName,
            credentialID: credentialID,
            verificationURL: verificationURL,
            issueDate: issueDate,
            hasEvidence: !evidenceURL.isEmpty
        )

        let result = await CertificateVerificationService.shared.verifyCredential(request: request)

        await MainActor.run {
            isVerifyingOnline = false
            verificationStatus = result.status
            verificationMethod = result.method
            verifiedAt = result.verifiedAt
            verificationSource = result.source

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
            verificationDetails = newRecord.toJSONString()

            switch result.status {
            case .automaticallyVerified:
                verificationFeedbackMessage = "Successfully verified against official issuer portal!"
                verificationFeedbackType = .success
            case .evidenceProvided:
                verificationFeedbackMessage = result.notes
                verificationFeedbackType = .info
            case .notVerified:
                verificationFeedbackMessage = result.notes
                verificationFeedbackType = .warning
            case .disputed:
                verificationFeedbackMessage = "Official issuer explicitly disputed or revoked this credential."
                verificationFeedbackType = .error
            case .issuerVerified:
                verificationFeedbackMessage = "Directly verified by issuing institution."
                verificationFeedbackType = .success
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedIssuer.isEmpty else {
            errorMessage = "Certificate title and issuer are required."
            return
        }

        let trimmedCredentialID = credentialID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVerificationURL = verificationURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let authenticatedSession = try? SupabaseManager.shared.validateActiveSession()
        let userUUID = authenticatedSession?.userUUID

        if let cert = certificate {
            // Update existing
            cert.title = trimmedTitle
            cert.issuer = trimmedIssuer
            cert.issueDate = issueDate
            cert.credentialID = trimmedCredentialID
            cert.verificationURL = trimmedVerificationURL
            cert.evidenceURL = evidenceURL
            cert.verificationStatus = verificationStatus
            cert.verificationMethod = verificationMethod
            cert.verifiedAt = verifiedAt
            cert.verificationSource = verificationSource
            cert.verificationDetails = verificationDetails
            cert.updatedAt = Date()

            // Update in Supabase only with valid active session
            if let uid = userUUID {
                let certID = cert.id
                Task {
                    struct UpdateCertPayload: Encodable {
                        let title: String
                        let issuer: String
                        let credential_id: String
                        let verification_url: String
                        let evidence_url: String
                        let verification_status: String
                    }
                    let payload = UpdateCertPayload(
                        title: trimmedTitle,
                        issuer: trimmedIssuer,
                        credential_id: trimmedCredentialID,
                        verification_url: trimmedVerificationURL,
                        evidence_url: cert.evidenceURL,
                        verification_status: cert.verificationStatus.rawValue
                    )
                    _ = try? await SupabaseManager.shared.client
                        .from("certificates")
                        .update(payload)
                        .eq("id", value: certID)
                        .eq("user_id", value: uid)
                        .execute()
                }
            }
        } else {
            // Create new
            let newCert = Certificate(
                id: UUID(),
                userID: userUUID,
                title: trimmedTitle,
                issuer: trimmedIssuer,
                issueDate: issueDate,
                credentialID: trimmedCredentialID,
                verificationURL: trimmedVerificationURL,
                evidenceURL: evidenceURL,
                verificationStatus: verificationStatus,
                verificationMethod: verificationMethod,
                verifiedAt: verifiedAt,
                verificationSource: verificationSource,
                verificationDetails: verificationDetails,
                createdAt: Date(),
                updatedAt: Date()
            )
            modelContext.insert(newCert)

            // Insert into Supabase only with valid active session
            if let uid = userUUID {
                Task {
                    struct InsertCertPayload: Encodable {
                        let id: UUID
                        let user_id: UUID
                        let title: String
                        let issuer: String
                        let credential_id: String
                        let verification_url: String
                        let evidence_url: String
                        let verification_status: String
                    }
                    let payload = InsertCertPayload(
                        id: newCert.id,
                        user_id: uid,
                        title: trimmedTitle,
                        issuer: trimmedIssuer,
                        credential_id: trimmedCredentialID,
                        verification_url: trimmedVerificationURL,
                        evidence_url: evidenceURL,
                        verification_status: verificationStatus.rawValue
                    )
                    // If verification_status column isn't created in Supabase yet, fallback gracefully
                    do {
                        _ = try await SupabaseManager.shared.client
                            .from("certificates")
                            .insert(payload)
                            .execute()
                    } catch {
                        // Fallback without verification_status if migration hasn't been run
                        struct FallbackPayload: Encodable {
                            let id: UUID
                            let user_id: UUID
                            let title: String
                            let issuer: String
                            let credential_id: String
                            let verification_url: String
                            let evidence_url: String
                        }
                        let fallback = FallbackPayload(
                            id: newCert.id,
                            user_id: uid,
                            title: trimmedTitle,
                            issuer: trimmedIssuer,
                            credential_id: trimmedCredentialID,
                            verification_url: trimmedVerificationURL,
                            evidence_url: evidenceURL
                        )
                        _ = try? await SupabaseManager.shared.client
                            .from("certificates")
                            .insert(fallback)
                            .execute()
                    }
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddCertificateView()
        .modelContainer(for: [Certificate.self], inMemory: true)
}
