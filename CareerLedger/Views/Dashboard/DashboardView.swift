import Combine
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var students: [Student]
    @Query(sort: \Semester.semesterNumber) private var semesters: [Semester]
    @Query(sort: \Achievement.date, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @Query(sort: \Certificate.issueDate, order: .reverse) private var certificates: [Certificate]
    @AppStorage("selectedTheme") private var selectedTheme = "dark"
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPublicProfile = false
    @State private var showingSettings = false
    @State private var showingCareerImport = false

    private var student: Student? {
        students.first
    }

    private var cgpa: Double {
        PortfolioMetrics.cgpa(from: semesters)
    }

    var body: some View {
        NavigationStack {
            AdaptivePage {
                VStack(spacing: 20) {
                    ViewThatFits(in: .horizontal) {
                        desktopLayout
                        phoneLayout
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color(red: 0.7, green: 0.72, blue: 0.8))
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showingCareerImport = true
                        } label: {
                            Label("Import Career Data", systemImage: "arrow.up.doc.fill")
                                .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                        }

                        Button {
                            showingPublicProfile = true
                        } label: {
                            Label("Public Profile", systemImage: "person.text.rectangle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCareerImport) {
                SmartCareerImportView()
                    .applyAppTheme()
            }
            .sheet(isPresented: $showingPublicProfile) {
                PublicProfileView()
                    .applyAppTheme()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .applyAppTheme()
            }
            .task {
                PersistenceController.seedIfNeeded(modelContext: modelContext)
            }
            .onAppear {
                triggerStaggeredEntrance()
            }
        }
    }

    @State private var revealedRows: Set<Int> = []
    @State private var highlightedRow: Int? = nil

    private var desktopLayout: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 18) {
                animatedRowView(index: 0) {
                    VStack(spacing: 14) {
                        header
                        importCareerDataBanner
                    }
                }

                animatedRowView(index: 4) {
                    verificationSummary
                }
            }
            .frame(minWidth: 360, maxWidth: 430)

            VStack(spacing: 18) {
                animatedRowView(index: 1) {
                    statsGrid(columns: 3)
                }
            }
        }
    }

    private var phoneLayout: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            // Row 0: Student Profile Header & Import Action
            animatedRowView(index: 0) {
                VStack(spacing: 14) {
                    header
                    importCareerDataBanner
                }
            }

            // Row 1: Academic CGPA & Projects
            animatedRowView(index: 1) {
                HStack(spacing: 14) {
                    StatCardView(title: "CGPA", value: cgpa > 0 ? String(format: "%.2f", cgpa) : "-", icon: "chart.line.uptrend.xyaxis", tint: .blue)
                    StatCardView(title: "Projects", value: "\(projects.count)", icon: "folder.fill", tint: .purple)
                }
            }

            // Row 2: Certificates & Achievements
            animatedRowView(index: 2) {
                HStack(spacing: 14) {
                    StatCardView(title: "Certificates", value: "\(certificates.count)", icon: "doc.text.fill", tint: .green)
                    StatCardView(title: "Achievements", value: "\(achievements.count)", icon: "trophy.fill", tint: .orange)
                }
            }

            // Row 3: Evidence & Total Records
            animatedRowView(index: 3) {
                HStack(spacing: 14) {
                    StatCardView(title: "Evidence", value: "\(evidenceRecordCount)", icon: "checkmark.seal.fill", tint: .teal)
                    StatCardView(title: "Total Records", value: "\(projects.count + achievements.count + certificates.count + semesters.count)", icon: "rectangle.stack.fill", tint: .indigo)
                }
            }

            // Row 4: Verification Summary Card
            animatedRowView(index: 4) {
                verificationSummary
            }
        }
    }

    @ViewBuilder
    private func animatedRowView<V: View>(index: Int, @ViewBuilder content: () -> V) -> some View {
        let isRevealed = revealedRows.contains(index)
        let isHighlighted = highlightedRow == index

        content()
            .opacity(isRevealed ? 1.0 : 0.0)
            .offset(y: isRevealed ? 0 : 26)
            .scaleEffect(isRevealed ? (isHighlighted ? 1.016 : 1.0) : 0.94)
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.78, blue: 1.0).opacity(0.85),
                                    Color(red: 0.85, green: 0.45, blue: 0.90).opacity(0.65),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isHighlighted)
    }

    private func triggerStaggeredEntrance() {
        revealedRows.removeAll()
        highlightedRow = nil

        for index in 0...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 + Double(index) * 0.14) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    _ = revealedRows.insert(index)
                    highlightedRow = index
                }
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.45)
                #endif
            }
        }

        // Smoothly fade out highlight ring after cascade finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 + 5 * 0.14 + 0.45) {
            withAnimation(.easeInOut(duration: 0.5)) {
                highlightedRow = nil
            }
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.65, blue: 1.0),
                                    Color(red: 0.20, green: 0.45, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CAREER LEDGER")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color(red: 0.45, green: 0.70, blue: 1.0))
                        Text(student?.name ?? "Shashwat Vatsyayan")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                        Text(student?.course ?? "B.E. Computer Science")
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.68, green: 0.70, blue: 0.78) : Color.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.50, green: 0.52, blue: 0.60))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var importCareerDataBanner: some View {
        Button {
            showingCareerImport = true
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Import Career Documents")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                        Text("Add resumes, transcripts, and verified certificates")
                            .font(.caption2)
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.65, green: 0.68, blue: 0.75) : Color.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.50, green: 0.52, blue: 0.60))
                }
            }
        }
        .buttonStyle(.plain)
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
        certificates.filter { $0.verificationStatus == .automaticallyVerified }.count +
        projects.filter { $0.verificationStatus == .sourceVerified }.count
    }

    private var evidenceProvidedCount: Int {
        achievements.filter { $0.verificationStatus == .evidenceProvided }.count +
        certificates.filter { $0.verificationStatus == .evidenceProvided }.count +
        projects.filter { $0.verificationStatus == .evidenceProvided }.count
    }

    private var selfReportedCount: Int {
        achievements.filter { $0.verificationStatus == .selfReported }.count +
        certificates.filter { $0.verificationStatus == .notVerified }.count +
        projects.filter { $0.verificationStatus == .selfReported }.count
    }
}

private struct VerificationCount: View {
    let label: String
    let value: Int
    let color: Color
    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            AnimatableCountText(
                currentValue: animatedValue,
                color: color
            )
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            animatedValue = 0
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = Double(value)
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = Double(newValue)
            }
        }
    }
}

private struct AnimatableCountText: View, Animatable {
    var currentValue: Double
    let color: Color

    var animatableData: Double {
        get { currentValue }
        set { currentValue = newValue }
    }

    var body: some View {
        Text("\(Int(round(currentValue)))")
            .font(.title3)
            .fontWeight(.heavy)
            .foregroundStyle(color)
    }
}


#Preview {
    DashboardView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Achievement.self, Project.self, Certificate.self], inMemory: true)
}
