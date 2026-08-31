import SwiftData
import SwiftUI

struct PublicProfileView: View {
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query private var projects: [Project]
    @Query private var achievements: [Achievement]
    @Query private var certificates: [Certificate]
    @State private var generatedPDFURL: URL?
    @State private var showingShareSheet = false
    @State private var showingVerificationMessage = false
    @State private var errorMessage: String?

    private var student: Student? {
        students.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    verificationOverview
                    evidenceSections
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.white, Color.blue.opacity(0.10), Color.purple.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Career Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Expo Verification", isPresented: $showingVerificationMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "This MVP uses local SwiftData records and demo verification statuses. A live issuer verification backend can be connected later.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let generatedPDFURL {
                    ShareSheet(activityItems: [generatedPDFURL])
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CAREER LEDGER")
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundStyle(.blue)
            Text(student?.name ?? "Student")
                .font(.largeTitle)
                .fontWeight(.heavy)
            Text(student?.course ?? "Computer Science Student")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(student?.university ?? "Chandigarh University")
                .font(.headline)
            if !semesters.isEmpty {
                Label("Education Verified", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var verificationOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            PublicStat(title: "Projects", value: "\(projects.count)", subtitle: "Projects")
            PublicStat(title: "Achievements", value: "\(issuerVerifiedAchievements)", subtitle: "Issuer Verified")
            PublicStat(title: "Evidence", value: "\(evidenceProvidedAchievements)", subtitle: "Evidence Provided")
            PublicStat(title: "Certificates", value: "\(verifiedCertificates)", subtitle: "Verified")
        }
    }

    private var evidenceSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Evidence Summary")
                .font(.title2)
                .fontWeight(.bold)

            PublicRow(title: "Education", detail: semesters.isEmpty ? "No academic records" : "CGPA \(String(format: "%.2f", PortfolioMetrics.cgpa(from: semesters)))", verified: !semesters.isEmpty)
            PublicRow(title: "Projects", detail: "\(projects.count) projects with \(projects.filter { !$0.githubURL.isEmpty }.count) GitHub links", verified: !projects.isEmpty)
            PublicRow(title: "Achievements", detail: "\(issuerVerifiedAchievements) issuer verified, \(evidenceProvidedAchievements) evidence provided, \(selfReportedAchievements) self reported", verified: issuerVerifiedAchievements > 0)
            PublicRow(title: "Certificates", detail: "\(verifiedCertificates) verified certificates", verified: verifiedCertificates > 0)
            PublicRow(title: "Skills", detail: student?.skills.isEmpty == false ? "Evidence available" : "No skills added", verified: student?.skills.isEmpty == false)

            Button {
                generateAndSharePDF()
            } label: {
                Label("Download / Share Career Ledger PDF", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                errorMessage = nil
                showingVerificationMessage = true
            } label: {
                Label("Verify Credentials", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var issuerVerifiedAchievements: Int {
        achievements.filter { $0.verificationStatus == .issuerVerified }.count
    }

    private var evidenceProvidedAchievements: Int {
        achievements.filter { $0.verificationStatus == .evidenceProvided }.count
    }

    private var selfReportedAchievements: Int {
        achievements.filter { $0.verificationStatus == .selfReported }.count
    }

    private var verifiedCertificates: Int {
        certificates.filter { $0.verificationStatus == .issuerVerified || $0.verificationStatus == .sourceVerified }.count
    }

    private func generateAndSharePDF() {
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
            errorMessage = "Could not generate the PDF. Please try again."
            showingVerificationMessage = true
        }
    }
}

private struct PublicStat: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.title)
                .fontWeight(.heavy)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

private struct PublicRow: View {
    let title: String
    let detail: String
    let verified: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: verified ? "checkmark.seal.fill" : "clock.fill")
                .foregroundStyle(verified ? .green : .secondary)
        }
        .padding()
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PublicProfileView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
