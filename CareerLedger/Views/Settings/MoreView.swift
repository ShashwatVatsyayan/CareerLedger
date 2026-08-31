import SwiftData
import SwiftUI

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @Query private var students: [Student]
    @Query private var semesters: [Semester]
    @Query private var projects: [Project]
    @Query private var achievements: [Achievement]
    @Query private var certificates: [Certificate]

    @State private var showingPublicProfile = false
    @State private var showingShareSheet = false
    @State private var showingEditProfile = false
    @State private var showingVerificationLegend = false
    @State private var showingResetAlert = false
    @State private var showingRefreshAlert = false
    @State private var refreshMessage = ""
    @State private var generatedPDFURL: URL?
    @State private var isGeneratingPDF = false

    private var student: Student? {
        students.first
    }

    private var totalRecords: Int {
        semesters.count + projects.count + achievements.count + certificates.count
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 20) {
                    profileOverviewCard
                    appearanceSection
                    dataManagementSection
                    shareAndExportSection
                    credentialsSection
                    legalSection
                    supportSection
                    accountSection
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showingPublicProfile) {
                PublicProfileView()
            }
            .sheet(isPresented: $showingEditProfile) {
                if let student {
                    EditProfileView(student: student)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let generatedPDFURL {
                    #if canImport(UIKit)
                    ShareSheet(activityItems: [generatedPDFURL])
                    #else
                    VStack(spacing: 16) {
                        Text("Career Ledger PDF Generated")
                            .font(.headline)
                        ShareLink(item: generatedPDFURL) {
                            Label("Save / Share PDF", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(30)
                    #endif
                }
            }
            .sheet(isPresented: $showingVerificationLegend) {
                VerificationLegendSheet()
            }
            .alert("Ledger Refreshed", isPresented: $showingRefreshAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(refreshMessage)
            }
            .alert("Reset Demo Records", isPresented: $showingResetAlert) {
                Button("Reset All", role: .destructive) {
                    resetToDemoData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will restore the standard showcase records for semesters, projects, certificates, and achievements.")
            }
        }
    }

    private var profileOverviewCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student?.name ?? "Shashwat Vatsyayan")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(student?.course ?? "B.E. Computer Science")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(student?.university ?? "Chandigarh University")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Edit") {
                    showingEditProfile = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var appearanceSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Settings & Appearance", subtitle: "Theme & Dark Mode Preferences")

                Picker("Theme", selection: $selectedTheme) {
                    Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                    Label("Light", systemImage: "sun.max.fill").tag("light")
                    Label("Dark", systemImage: "moon.fill").tag("dark")
                }
                .pickerStyle(.segmented)

                HStack {
                    Image(systemName: selectedTheme == "dark" ? "moon.stars.fill" : (selectedTheme == "light" ? "sun.max.fill" : "circle.lefthalf.filled"))
                        .foregroundStyle(selectedTheme == "dark" ? .indigo : .orange)
                    Text(selectedTheme == "dark" ? "Dark Mode Active: Applies deeply across all screens and sheets" : (selectedTheme == "light" ? "Light Mode Active" : "Following System Appearance"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var dataManagementSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Database & Sync", subtitle: "\(totalRecords) verified records stored in SwiftData")

                Button {
                    forceRefresh()
                } label: {
                    HStack {
                        Label("Force Refresh Ledger", systemImage: "arrow.clockwise.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showingResetAlert = true
                } label: {
                    Label("Restore Showcase Demo Data", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var shareAndExportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Public Profile & PDF", subtitle: "Export your verified credentials")

                HStack(spacing: 12) {
                    Button {
                        showingPublicProfile = true
                    } label: {
                        Label("Public Ledger", systemImage: "person.text.rectangle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        generateAndExportPDF()
                    } label: {
                        Label(isGeneratingPDF ? "Generating..." : "Export PDF", systemImage: "doc.text.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isGeneratingPDF)
                }
            }
        }
    }

    private var credentialsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Credentials & Certificates", subtitle: "\(certificates.count) certificates on file")

                NavigationLink {
                    CertificatesView()
                } label: {
                    HStack {
                        Label("Manage Certificates", systemImage: "doc.text.badge.plus")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingVerificationLegend = true
                } label: {
                    HStack {
                        Label("Verification Status Guide", systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        Spacer()
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var legalSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Legal & Transparency")

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                NavigationLink {
                    TermsAndConditionsView()
                } label: {
                    HStack {
                        Label("Terms & Conditions", systemImage: "doc.plaintext.fill")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var supportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Support & About")

                NavigationLink {
                    HelpView()
                } label: {
                    HStack {
                        Label("Help Guide & FAQ", systemImage: "questionmark.circle.fill")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                HStack {
                    Label("Career Ledger Version", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("1.2 (Expo Build)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accountSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Account Session")

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Signed In As")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(student?.email ?? "student@example.com")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }

                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isLoggedIn = false
                    }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private func forceRefresh() {
        PersistenceController.seedIfNeeded(modelContext: modelContext)
        try? modelContext.save()
        let cgpa = PortfolioMetrics.cgpa(from: semesters)
        refreshMessage = "Database synchronized successfully.\n\n• Semesters: \(semesters.count) (CGPA \(String(format: "%.2f", cgpa)))\n• Projects: \(projects.count)\n• Achievements: \(achievements.count)\n• Certificates: \(certificates.count)\n• Total Records: \(totalRecords)"
        showingRefreshAlert = true
    }

    private func resetToDemoData() {
        // Delete all
        semesters.forEach(modelContext.delete)
        projects.forEach(modelContext.delete)
        achievements.forEach(modelContext.delete)
        certificates.forEach(modelContext.delete)
        students.forEach(modelContext.delete)
        try? modelContext.save()

        // Re-seed
        PersistenceController.seedIfNeeded(modelContext: modelContext)
        try? modelContext.save()

        refreshMessage = "All records have been reset to default verified showcase items."
        showingRefreshAlert = true
    }

    private func generateAndExportPDF() {
        isGeneratingPDF = true
        do {
            generatedPDFURL = try PDFService.generateCareerLedgerPDF(
                student: student,
                semesters: semesters,
                projects: projects,
                achievements: achievements,
                certificates: certificates
            )
            showingShareSheet = true
        } catch {
            refreshMessage = "Could not generate PDF: \(error.localizedDescription)"
            showingRefreshAlert = true
        }
        isGeneratingPDF = false
    }
}

private struct VerificationLegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AdaptivePage {
                VStack(alignment: .leading, spacing: 16) {
                    legendRow(
                        title: "Issuer Verified",
                        subtitle: "Cryptographically verified or officially issued by an authorized institution / academy.",
                        badgeStatus: .issuerVerified
                    )

                    legendRow(
                        title: "Source Verified",
                        subtitle: "Directly linked to a verified source code repository or verified deployment.",
                        badgeStatus: .sourceVerified
                    )

                    legendRow(
                        title: "Evidence Provided",
                        subtitle: "Accompanied by verifiable evidence URLs, credential IDs, or documentation artifacts.",
                        badgeStatus: .evidenceProvided
                    )

                    legendRow(
                        title: "Self Reported",
                        subtitle: "Entered by the student and awaiting external verification link or certificate validation.",
                        badgeStatus: .selfReported
                    )
                }
            }
            .navigationTitle("Verification Badges")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func legendRow(title: String, subtitle: String, badgeStatus: VerificationStatus) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    VerificationBadge(status: badgeStatus)
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MoreView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
