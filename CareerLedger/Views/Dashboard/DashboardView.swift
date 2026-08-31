import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]
    @State private var showingPublicProfile = false

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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingPublicProfile = true
                    } label: {
                        Label("Public Profile", systemImage: "person.text.rectangle")
                    }
                }
            }
            .sheet(isPresented: $showingPublicProfile) {
                PublicProfileView()
            }
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
            }
            .frame(minWidth: 360, maxWidth: 430)

            VStack(spacing: 18) {
                statsGrid(columns: 3)
                ledgerReadinessCard
            }
        }
    }

    private var phoneLayout: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            header
            statsGrid(columns: 2)
            verificationSummary
            ledgerReadinessCard
        }
    }

    private var header: some View {
        Button {
            showingPublicProfile = true
        } label: {
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
                        Text(student?.name ?? "Shashwat Vatsyayan")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(.primary)
                        Text(student?.course ?? "B.E. Computer Science")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
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
                SectionHeader(title: "Verification Overview", subtitle: "\(projects.count + achievements.count + certificates.count + semesters.count) total database records")
                HStack {
                    VerificationCount(label: "Issuer", value: issuerVerifiedCount, color: .green)
                    VerificationCount(label: "Source", value: sourceVerifiedCount, color: .purple)
                    VerificationCount(label: "Evidence", value: evidenceProvidedCount, color: .blue)
                    VerificationCount(label: "Self", value: selfReportedCount, color: .secondary)
                }
            }
        }
    }

    private var ledgerReadinessCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Portfolio Summary", subtitle: "Verifiable student credentials")

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(evidenceRecordCount) Evidence Links")
                            .font(.headline)
                        Text("Connected across projects, certifications, and awards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showingPublicProfile = true
                    } label: {
                        Label("View Ledger", systemImage: "arrow.up.right")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
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

#Preview {
    DashboardView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Achievement.self, Project.self, Certificate.self], inMemory: true)
}
