import SwiftData
import SwiftUI

struct PublicProfileView: View {
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]
    @State private var generatedPDFURL: URL?
    @State private var showingShareSheet = false
    @State private var showingVerificationMessage = false
    @State private var errorMessage: String?
    @State private var isGeneratingPDF = false

    private var student: Student? {
        students.first
    }

    private var cgpa: Double {
        PortfolioMetrics.cgpa(from: semesters)
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 20) {
                    hero
                    verificationOverview
                    actionButtons
                    educationSection
                    projectsSection
                    achievementsSection
                    certificatesSection
                    skillsSection
                    linksSection
                }
            }
            .navigationTitle("Public Career Ledger")
            .inlineNavigationBarTitle()
            .alert("Career Ledger Verification", isPresented: $showingVerificationMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "This record is powered by local SwiftData with cryptographically verifiable evidence references for project expo demonstrations.")
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
        }
    }

    private var hero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("CAREER LEDGER")
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundStyle(.blue)
                            Spacer()
                            Label("Verified Record", systemImage: "checkmark.seal.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }

                        Text(student?.name ?? "Student")
                            .font(.title)
                            .fontWeight(.heavy)

                        Text(student?.course ?? "Computer Science Student")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(student?.university ?? "Chandigarh University")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                if let bio = student?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var verificationOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Overview", subtitle: "\(projects.count + achievements.count + certificates.count + semesters.count) verified records")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    PublicStat(title: "Projects", value: "\(projects.count)", subtitle: "\(projects.filter { !$0.githubURL.isEmpty }.count) Connected Repos")
                    PublicStat(title: "Achievements", value: "\(achievements.count)", subtitle: "\(issuerVerifiedAchievements) Issuer Verified")
                    PublicStat(title: "Certificates", value: "\(certificates.count)", subtitle: "\(verifiedCertificates) Verified")
                    PublicStat(title: "Education", value: cgpa > 0 ? String(format: "%.2f", cgpa) : "-", subtitle: "\(semesters.count) Semesters")
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                generateAndSharePDF()
            } label: {
                Label(isGeneratingPDF ? "Generating..." : "Download Verified PDF", systemImage: "arrow.down.doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isGeneratingPDF)

            Button {
                errorMessage = nil
                showingVerificationMessage = true
            } label: {
                Label("Verify Ledger", systemImage: "checkmark.shield")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Education", subtitle: semesters.isEmpty ? "No academic records" : "Overall CGPA \(String(format: "%.2f", cgpa))")
            if semesters.isEmpty {
                Text("No semester records added.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(semesters) { semester in
                    SemesterTimelineCard(semester: semester, isExpanded: true, onToggle: { })
                }
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Projects", subtitle: "\(projects.count) project records")
            if projects.isEmpty {
                Text("No projects added.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(projects) { project in
                    ProjectRecordCard(project: project, isPublic: true)
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Achievements", subtitle: "\(achievements.count) achievement records")
            if achievements.isEmpty {
                Text("No achievements added.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(achievements) { achievement in
                    AchievementRecordCard(achievement: achievement, isPublic: true)
                }
            }
        }
    }

    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Certificates", subtitle: "\(certificates.count) certificate records")
            if certificates.isEmpty {
                Text("No certificates added.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(certificates) { certificate in
                    CertificateRecordCard(certificate: certificate, isPublic: true)
                }
            }
        }
    }

    private var skillsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Verified Skills", subtitle: "Backed by projects and certificates")
                if let skills = student?.skills, !skills.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(skills, id: \.self) { skill in
                            Text(skill)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    Text("No skills listed.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var linksSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Professional Profiles")
                if let github = student?.githubURL, let url = validURL(github) {
                    Link(destination: url) {
                        HStack {
                            Label("GitHub", systemImage: "chevron.left.slash.chevron.right")
                            Spacer()
                            Text(github)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                    }
                }
                if let linkedin = student?.linkedinURL, let url = validURL(linkedin) {
                    Link(destination: url) {
                        HStack {
                            Label("LinkedIn", systemImage: "link")
                            Spacer()
                            Text(linkedin)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                    }
                }
                if let portfolio = student?.portfolioURL, let url = validURL(portfolio) {
                    Link(destination: url) {
                        HStack {
                            Label("Portfolio", systemImage: "globe")
                            Spacer()
                            Text(portfolio)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }

    private var issuerVerifiedAchievements: Int {
        achievements.filter { $0.verificationStatus == .issuerVerified }.count
    }

    private var verifiedCertificates: Int {
        certificates.filter { $0.verificationStatus == .issuerVerified || $0.verificationStatus == .sourceVerified }.count
    }

    private func generateAndSharePDF() {
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
            errorMessage = "Could not generate the PDF. Please try again."
            showingVerificationMessage = true
        }
        isGeneratingPDF = false
    }
}

private struct PublicStat: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(.blue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PublicProfileView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
