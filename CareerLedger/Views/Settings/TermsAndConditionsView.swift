import SwiftUI

struct TermsAndConditionsView: View {
    var body: some View {
        AdaptivePage {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Terms & Conditions", systemImage: "doc.plaintext.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.purple)

                        Text("Last updated: August 2026")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Please review the terms governing the use of the Career Ledger verifiable student portfolio application.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                termsSection(
                    title: "1. Acceptance of Terms",
                    icon: "checkmark.circle.fill",
                    content: "By using Career Ledger, you agree to maintain accurate academic records, project artifacts, and achievement credentials in accordance with academic integrity guidelines."
                )

                termsSection(
                    title: "2. Verifiable Evidence Standards",
                    icon: "link.circle.fill",
                    content: "Evidence URLs provided for hackathons, certifications, and projects should lead to valid, accessible artifacts (e.g. GitHub repositories, live demo deployments, and credential validation URLs)."
                )

                termsSection(
                    title: "3. Academic Integrity",
                    icon: "graduationcap.fill",
                    content: "Semester SGPA and subject grades entered into the ledger represent self-managed academic tracking. Official grade certification remains under the authority of your academic institution."
                )

                termsSection(
                    title: "4. Intellectual Property & Export Rights",
                    icon: "doc.richtext.fill",
                    content: "All project content, descriptions, and portfolios created by the student remain the intellectual property of the student. Career Ledger grants you unrestricted rights to export and distribute your verified PDF resume."
                )

                termsSection(
                    title: "5. Disclaimer of Warranties",
                    icon: "shield.lefthalf.filled",
                    content: "Career Ledger is provided as a portfolio management and expo showcase tool. The application is provided 'as is' without warranties of third-party employment guarantees."
                )
            }
        }
        .navigationTitle("Terms & Conditions")
        .inlineNavigationBarTitle()
    }

    private func termsSection(title: String, icon: String, content: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.purple)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TermsAndConditionsView()
    }
}
