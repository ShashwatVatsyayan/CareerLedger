import SwiftUI

struct CertificatesView: View {
    @State private var certificates = sampleCertificates
    @State private var showingAddCertificate = false
    @State private var editingCertificate: Certificate?

    var body: some View {
        NavigationStack {
            List {
                ForEach(certificates) { certificate in
                    CertificateCardView(
                        certificate: certificate,
                        onEdit: { editingCertificate = certificate },
                        onDelete: { deleteCertificate(certificate) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteCertificate(certificate)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingCertificate = certificate
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.green.opacity(0.06))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: certificates.count)
            .navigationTitle("Certificates")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddCertificate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCertificate) {
                AddCertificateView { certificate in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        certificates.append(certificate)
                    }
                }
            }
            .sheet(item: $editingCertificate) { certificate in
                AddCertificateView(certificate: certificate) { updatedCertificate in
                    updateCertificate(certificate, with: updatedCertificate)
                }
            }
        }
    }

    private func updateCertificate(_ oldCertificate: Certificate, with updatedCertificate: Certificate) {
        guard let index = certificates.firstIndex(where: { $0.id == oldCertificate.id }) else {
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            certificates[index] = updatedCertificate
        }
    }

    private func deleteCertificate(_ certificate: Certificate) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            certificates.removeAll { $0.id == certificate.id }
        }
    }
}

private struct CertificateCardView: View {
    let certificate: Certificate
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.green.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(certificate.title)
                    .font(.headline)
                Text(certificate.organization)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Credential ID: \(certificate.credentialID)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
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
    CertificatesView()
}
