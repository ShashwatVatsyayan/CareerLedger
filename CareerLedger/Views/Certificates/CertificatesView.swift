import SwiftData
import SwiftUI

struct CertificatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]
    @State private var showingAddCertificate = false
    @State private var editingCertificate: Certificate?
    @State private var searchText = ""
    @State private var selectedStatus: VerificationStatus?

    private var filteredCertificates: [Certificate] {
        certificates.filter { certificate in
            let matchesSearch = searchText.isEmpty ||
            certificate.title.localizedCaseInsensitiveContains(searchText) ||
            certificate.issuer.localizedCaseInsensitiveContains(searchText) ||
            certificate.credentialID.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || certificate.verificationStatus == selectedStatus
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Certificates", subtitle: "\(certificates.count) credential records")
                    filterBar

                    if filteredCertificates.isEmpty {
                        PremiumEmptyState(
                            title: "No Certificates Yet",
                            message: "Add certificates with issuers, credential IDs, verification URLs, and proof.",
                            systemImage: "doc.badge.plus",
                            actionTitle: "Add Certificate",
                            action: { showingAddCertificate = true }
                        )
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                            ForEach(filteredCertificates) { certificate in
                                CertificateRecordCard(
                                    certificate: certificate,
                                    onEdit: { editingCertificate = certificate },
                                    onDelete: { deleteCertificate(certificate) }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search certificates")
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: filteredCertificates.count)
            .navigationTitle("Certificates")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddCertificate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
            .sheet(isPresented: $showingAddCertificate) {
                AddCertificateView()
            }
            .sheet(item: $editingCertificate) { certificate in
                AddCertificateView(certificate: certificate)
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

    private func deleteCertificate(_ certificate: Certificate) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            modelContext.delete(certificate)
            try? modelContext.save()
        }
    }
}

struct CertificateRecordCard: View {
    let certificate: Certificate
    var isPublic: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.green.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(certificate.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Issued by \(certificate.issuer)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(certificate.issueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VerificationBadge(status: certificate.verificationStatus)
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

                if !certificate.credentialID.isEmpty {
                    LabeledContent("Credential ID", value: certificate.credentialID)
                        .font(.caption)
                }

                EvidenceSection(items: evidenceItems)

                if !isPublic, validURL(certificate.verificationURL) != nil {
                    Link(destination: validURL(certificate.verificationURL)!) {
                        Label("Verify Credential", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var evidenceItems: [EvidenceItem] {
        var items: [EvidenceItem] = []
        if !certificate.credentialID.isEmpty {
            items.append(EvidenceItem(title: "Credential ID", detail: certificate.credentialID, url: nil, icon: "number"))
        }
        if let url = validURL(certificate.verificationURL) {
            items.append(EvidenceItem(title: "Verification URL", detail: certificate.verificationURL, url: url, icon: "checkmark.shield.fill"))
        }
        return items
    }
}

#Preview {
    CertificatesView()
        .modelContainer(for: [Certificate.self], inMemory: true)
}
