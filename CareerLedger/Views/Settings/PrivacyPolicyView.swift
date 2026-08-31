import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        AdaptivePage {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Text("Last updated: August 2026")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Career Ledger is designed with privacy-first principles. Your academic and career data belongs solely to you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                policySection(
                    title: "1. On-Device Local Storage",
                    icon: "externaldrive.fill",
                    content: "All your profile records, semesters, subject grades, project details, achievements, and certificate credentials are stored locally on your device using Apple's SwiftData framework with hardware-backed encryption."
                )

                policySection(
                    title: "2. Zero Tracking & Telemetry",
                    icon: "eye.slash.fill",
                    content: "Career Ledger does not collect personal analytics, advertising IDs, or behavioral telemetry. No third-party trackers or ad SDKs are included in this application."
                )

                policySection(
                    title: "3. Verified Public Sharing",
                    icon: "lock.shield.fill",
                    content: "When you choose to share your Public Career Ledger or export a verified PDF, data is rendered directly on your device. You have full control over what evidence links, repository URLs, and credentials you share with recruiters or evaluators."
                )

                policySection(
                    title: "4. Cryptographic Evidence & Verification",
                    icon: "checkmark.seal.fill",
                    content: "Evidence URLs and credential IDs are stored as local hashable references. Verification statuses indicate whether records are self-reported, evidence-backed, source-linked, or issuer-verified."
                )

                policySection(
                    title: "5. Data Erasure & Portability",
                    icon: "arrow.triangle.2.circlepath",
                    content: "You can edit or permanently delete any record at any time. Deleting records in the app removes them immediately from local persistent storage."
                )
            }
        }
        .navigationTitle("Privacy Policy")
        .inlineNavigationBarTitle()
    }

    private func policySection(title: String, icon: String, content: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
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
        PrivacyPolicyView()
    }
}
