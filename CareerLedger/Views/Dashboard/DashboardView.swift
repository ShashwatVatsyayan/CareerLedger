import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]

    private var student: Student? {
        students.first
    }

    private var cgpa: Double {
        PortfolioMetrics.cgpa(from: semesters)
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                ViewThatFits(in: .horizontal) {
                    desktopLayout
                    phoneLayout
                }
            }
            .navigationTitle("Dashboard")
            .task {
                PersistenceController.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    private var desktopLayout: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 18) {
                header
                verificationSummary
                academicsPreview
            }
            .frame(minWidth: 360, maxWidth: 430)

            VStack(spacing: 18) {
                statsGrid(columns: 3)
                recentActivity
                recordPreview
            }
        }
    }

    private var phoneLayout: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            header
            statsGrid(columns: 2)
            verificationSummary
            recentActivity
            academicsPreview
            recordPreview
        }
    }

    private var header: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.blue.gradient)

                VStack(alignment: .leading, spacing: 6) {
                    Text("CAREER LEDGER")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.blue)
                    Text(student?.name ?? "Student")
                        .font(.title)
                        .fontWeight(.heavy)
                    Text(student?.course ?? "Build your verified career record")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func statsGrid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 14) {
            StatCardView(title: "CGPA", value: cgpa > 0 ? String(format: "%.2f", cgpa) : "-", icon: "chart.line.uptrend.xyaxis", tint: .blue)
            StatCardView(title: "Projects", value: "\(projects.count)", icon: "folder.fill", tint: .purple)
            StatCardView(title: "Certificates", value: "\(certificates.count)", icon: "doc.text.fill", tint: .green)
            StatCardView(title: "Achievements", value: "\(achievements.count)", icon: "trophy.fill", tint: .orange)
            StatCardView(title: "Evidence", value: "\(evidenceRecordCount)", icon: "checkmark.seal.fill", tint: .teal)
            StatCardView(title: "Total Records", value: "\(projects.count + achievements.count + certificates.count + semesters.count)", icon: "rectangle.stack.fill", tint: .indigo)
        }
    }

    private var verificationSummary: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Verification Overview", subtitle: "\(projects.count + achievements.count + certificates.count + semesters.count) total records")
                HStack {
                    VerificationCount(label: "Issuer", value: issuerVerifiedCount, color: .green)
                    VerificationCount(label: "Source", value: sourceVerifiedCount, color: .purple)
                    VerificationCount(label: "Evidence", value: evidenceProvidedCount, color: .blue)
                    VerificationCount(label: "Self", value: selfReportedCount, color: .secondary)
                }
            }
        }
    }

    private var recentActivity: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recent Activity", subtitle: "Latest records from SwiftData")

                if achievements.isEmpty && projects.isEmpty && certificates.isEmpty {
                    Text("Add records to see recent activity.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(achievements.prefix(2))) { achievement in
                        ActivityRow(icon: "trophy.fill", tint: .orange, title: achievement.title, subtitle: achievement.verificationStatus.displayName)
                    }
                    ForEach(Array(projects.prefix(2))) { project in
                        ActivityRow(icon: "folder.fill", tint: .purple, title: project.name, subtitle: project.technologies)
                    }
                    ForEach(Array(certificates.prefix(1))) { certificate in
                        ActivityRow(icon: "doc.text.fill", tint: .green, title: certificate.title, subtitle: certificate.verificationStatus.displayName)
                    }
                }
            }
        }
    }

    private var academicsPreview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Academic Progress", subtitle: semesters.isEmpty ? "No semesters yet" : "CGPA \(String(format: "%.2f", cgpa))")

                ForEach(Array(semesters.prefix(4))) { semester in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Semester \(semester.semesterNumber)")
                                .font(.headline)
                            Text("\(semester.subjects.count) subjects")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.1f", semester.sgpa))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private var recordPreview: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Career Records", subtitle: "Actual evidence, not only counts")
                ForEach(Array(projects.prefix(2))) { project in
                    ProjectMiniRow(project: project)
                }
                ForEach(Array(achievements.prefix(2))) { achievement in
                    AchievementMiniRow(achievement: achievement)
                }
            }
        }
    }

    private var evidenceRecordCount: Int {
        projects.filter { !$0.githubURL.isEmpty || !$0.demoURL.isEmpty }.count +
        achievements.filter { !$0.evidenceURL.isEmpty || !$0.credentialID.isEmpty }.count +
        certificates.filter { !$0.verificationURL.isEmpty || !$0.credentialID.isEmpty }.count
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
}

private struct VerificationCount: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProjectMiniRow: View {
    let project: Project

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.headline)
                Text(project.technologies)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VerificationBadge(status: project.verificationStatus)
        }
    }
}

private struct AchievementMiniRow: View {
    let achievement: Achievement

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.organization)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VerificationBadge(status: achievement.verificationStatus)
        }
    }
}

private struct ActivityRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Achievement.self, Project.self, Certificate.self], inMemory: true)
}
