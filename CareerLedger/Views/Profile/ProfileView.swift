import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingPublicProfile = false
    @State private var showingShareSheet = false
    @State private var generatedPDFURL: URL?
    @State private var pdfError: String?
    @State private var isGeneratingPDF = false

    private var student: Student? {
        students.first
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                LazyVStack(alignment: .leading, spacing: 20) {
                    CareerProfileHeader(student: student)
                    verificationOverview
                    sharePanel
                    actualRecords
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem {
                    Button("Edit") {
                        if student == nil {
                            let newStudent = Student(
                                name: "Shashwat Vatsyayan",
                                course: "B.E. Computer Science",
                                university: "Chandigarh University",
                                email: "student@example.com",
                                bio: ""
                            )
                            modelContext.insert(newStudent)
                            try? modelContext.save()
                        }
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let student {
                    EditProfileView(student: student)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingPublicProfile) {
                PublicProfileView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareCareerLedgerSheet(
                    isGenerating: $isGeneratingPDF,
                    pdfURL: $generatedPDFURL,
                    errorMessage: $pdfError,
                    generatePDF: generatePDF
                )
            }
        }
    }

    private var verificationOverview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Verification Overview", subtitle: "\(totalRecords) total records")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                    ProfileStat(title: "Issuer Verified", value: issuerVerifiedCount, color: .green)
                    ProfileStat(title: "Source Verified", value: sourceVerifiedCount, color: .purple)
                    ProfileStat(title: "Evidence Provided", value: evidenceProvidedCount, color: .blue)
                    ProfileStat(title: "Self Reported", value: selfReportedCount, color: .secondary)
                }
            }
        }
    }

    private var sharePanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Career Ledger Profile", subtitle: student?.portfolioURL ?? "careerledger.app/u/demo")
                HStack {
                    Button {
                        copyProfileLink()
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingPublicProfile = true
                    } label: {
                        Label("Public Preview", systemImage: "person.text.rectangle")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share Career Ledger", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var actualRecords: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 18) {
                    educationSection
                    skillsSection
                    linksSection
                }
                VStack(spacing: 18) {
                    projectsSection
                    achievementsSection
                    certificatesSection
                }
            }
            LazyVStack(alignment: .leading, spacing: 18) {
                educationSection
                projectsSection
                achievementsSection
                certificatesSection
                skillsSection
                linksSection
            }
        }
    }

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Education", subtitle: semesters.isEmpty ? "No academic records" : "CGPA \(String(format: "%.2f", PortfolioMetrics.cgpa(from: semesters)))")
            ForEach(semesters) { semester in
                SemesterTimelineCard(semester: semester, isExpanded: false, onToggle: { })
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Projects", subtitle: "\(projects.count) projects")
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
            SectionHeader(title: "Achievements", subtitle: "\(achievements.count) achievements")
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
            SectionHeader(title: "Certificates", subtitle: "\(certificates.count) certificates")
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
                SectionHeader(title: "Skills", subtitle: "Evidence comes from linked records")
                FlowLayout(items: student?.skills ?? [])
            }
        }
    }

    private var linksSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Professional Links")
                LinkLine(title: "GitHub", value: student?.githubURL ?? "", icon: "chevron.left.slash.chevron.right")
                LinkLine(title: "LinkedIn", value: student?.linkedinURL ?? "", icon: "link")
                LinkLine(title: "Portfolio", value: student?.portfolioURL ?? "", icon: "globe")
            }
        }
    }

    private var totalRecords: Int {
        projects.count + achievements.count + certificates.count + semesters.count
    }

    private var issuerVerifiedCount: Int {
        achievements.filter { $0.verificationStatus == .issuerVerified }.count +
        certificates.filter { $0.verificationStatus == .issuerVerified }.count +
        projects.filter { $0.verificationStatus == .issuerVerified }.count
    }

    private var sourceVerifiedCount: Int {
        achievements.filter { $0.verificationStatus == .sourceVerified }.count +
        certificates.filter { $0.verificationStatus == .sourceVerified }.count +
        projects.filter { $0.verificationStatus == .sourceVerified }.count
    }

    private var evidenceProvidedCount: Int {
        achievements.filter { $0.verificationStatus == .evidenceProvided }.count +
        certificates.filter { $0.verificationStatus == .evidenceProvided }.count +
        projects.filter { $0.verificationStatus == .evidenceProvided }.count
    }

    private var selfReportedCount: Int {
        achievements.filter { $0.verificationStatus == .selfReported }.count +
        certificates.filter { $0.verificationStatus == .selfReported }.count +
        projects.filter { $0.verificationStatus == .selfReported }.count
    }

    private func copyProfileLink() {
        #if canImport(UIKit)
        UIPasteboard.general.string = student?.portfolioURL ?? "https://careerledger.example.com/demo"
        #endif
    }

    private func generatePDF() {
        isGeneratingPDF = true
        pdfError = nil

        do {
            generatedPDFURL = try PDFService.generateCareerLedgerPDF(
                student: student,
                semesters: semesters,
                projects: projects,
                achievements: achievements,
                certificates: certificates
            )
        } catch {
            pdfError = "Could not generate the PDF. Please try again."
        }

        isGeneratingPDF = false
    }
}

struct CareerProfileHeader: View {
    let student: Student?

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 18) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.bounce, value: student?.name ?? "")

                VStack(alignment: .leading, spacing: 8) {
                    Text("CAREER LEDGER")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.blue)
                    Text(student?.name ?? "Student")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    Text(student?.course ?? "Add your degree")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(student?.university ?? "Add your university")
                        .font(.headline)
                    Text(student?.bio.isEmpty == false ? student?.bio ?? "" : "Add a short professional bio.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct ProfileStat: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LinkLine: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        if let url = validURL(value) {
            Link(destination: url) {
                HStack {
                    Label(title, systemImage: icon)
                    Spacer()
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ShareCareerLedgerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isGenerating: Bool
    @Binding var pdfURL: URL?
    @Binding var errorMessage: String?
    let generatePDF: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 8) {
                    Text("Share Career Ledger")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your complete career profile is ready to share.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(["Education", "Projects", "Achievements", "Certificates", "Skills", "Evidence", "Verification Status", "Professional Links"], id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if isGenerating {
                    ProgressView("Generating PDF")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {
                    generatePDF()
                } label: {
                    Label("Generate PDF", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isGenerating)

                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackground())
            .navigationTitle("Share")
            .inlineNavigationBarTitle()
        }
    }
}

private struct FlowLayout: View {
    let items: [String]

    var body: some View {
        if items.isEmpty {
            Text("No skills added.")
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
