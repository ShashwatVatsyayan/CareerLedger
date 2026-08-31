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
    @State private var showingPublicProfile = false
    @State private var showingShareSheet = false
    @State private var generatedPDFURL: URL?
    @State private var isGeneratingPDF = false
    @State private var copyFeedbackMessage: String?
    @State private var showingCopyAlert = false

    private var student: Student? {
        students.first
    }

    private var cgpa: Double {
        PortfolioMetrics.cgpa(from: semesters)
    }

    private var totalRecords: Int {
        semesters.count + projects.count + achievements.count + certificates.count
    }

    private var totalEvidence: Int {
        projects.filter { !$0.githubURL.isEmpty || !$0.demoURL.isEmpty }.count +
        achievements.filter { !$0.evidenceURL.isEmpty || !$0.credentialID.isEmpty }.count +
        certificates.filter { !$0.verificationURL.isEmpty || !$0.credentialID.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            AdaptivePage(maxWidth: 720) {
                VStack(spacing: 24) {
                    minimalIdentityCard
                    executiveSummaryCard
                    skillsCard
                    contactAndLinksCard
                    quickActionsCard
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Profile")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditProfile = true
                    } label: {
                        Text("Edit")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let student {
                    EditProfileView(student: student)
                }
            }
            .sheet(isPresented: $showingPublicProfile) {
                PublicProfileView()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let generatedPDFURL {
                    #if canImport(UIKit)
                    ShareSheet(activityItems: [generatedPDFURL])
                    #else
                    VStack(spacing: 16) {
                        Text("Career Ledger PDF")
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
            .alert("Copied to Clipboard", isPresented: $showingCopyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(copyFeedbackMessage ?? "Link copied.")
            }
        }
    }

    // MARK: - 1. Minimal Identity Card
    private var minimalIdentityCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 96, height: 96)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                }

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(student?.name ?? "Shashwat Vatsyayan")
                            .font(.title)
                            .fontWeight(.heavy)

                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }

                    Text(student?.course ?? "B.E. Computer Science")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.85))

                    Text(student?.university ?? "Chandigarh University")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let bio = student?.bio, !bio.isEmpty {
                    Text("“\(bio)”")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 12) {
                    Button {
                        showingPublicProfile = true
                    } label: {
                        Label("Public Ledger", systemImage: "arrow.up.right.square.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button {
                        generateAndExportPDF()
                    } label: {
                        Label(isGeneratingPDF ? "Generating..." : "Export CV", systemImage: "doc.text.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(isGeneratingPDF)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 2. Executive Academic & Verification Summary
    private var executiveSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("ACADEMIC & LEDGER FOOTPRINT")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    summaryPill(
                        title: "Current CGPA",
                        value: cgpa > 0 ? String(format: "%.2f", cgpa) : "N/A",
                        subtitle: "\(semesters.count) Semesters",
                        tint: .blue
                    )

                    Divider()

                    summaryPill(
                        title: "Verified Proofs",
                        value: "\(totalEvidence)",
                        subtitle: "Evidence Artifacts",
                        tint: .teal
                    )

                    Divider()

                    summaryPill(
                        title: "Ledger Records",
                        value: "\(totalRecords)",
                        subtitle: "SwiftData Items",
                        tint: .purple
                    )
                }
            }
        }
    }

    private func summaryPill(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(tint)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Skills Matrix
    private var skillsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CORE COMPETENCIES")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\((student?.skills ?? []).count) Skills")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let skills = student?.skills, !skills.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(skills, id: \.self) { skill in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                Text(skill)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                        }
                    }
                } else {
                    Text("No skills added yet. Tap Edit to add your technical skills.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 4. Contact & Professional Profiles
    private var contactAndLinksCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("VERIFIED PROFILES & CONTACT")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    profileLinkRow(
                        title: "Email Address",
                        value: student?.email ?? "student@example.com",
                        icon: "envelope.fill",
                        tint: .red,
                        url: URL(string: "mailto:\(student?.email ?? "")")
                    )

                    Divider()

                    profileLinkRow(
                        title: "GitHub Profile",
                        value: student?.githubURL ?? "Add GitHub",
                        icon: "chevron.left.slash.chevron.right",
                        tint: .primary,
                        url: validURL(student?.githubURL ?? "")
                    )

                    Divider()

                    profileLinkRow(
                        title: "LinkedIn Network",
                        value: student?.linkedinURL ?? "Add LinkedIn",
                        icon: "link",
                        tint: .blue,
                        url: validURL(student?.linkedinURL ?? "")
                    )

                    Divider()

                    profileLinkRow(
                        title: "Portfolio Website",
                        value: student?.portfolioURL ?? "Add Portfolio",
                        icon: "globe",
                        tint: .purple,
                        url: validURL(student?.portfolioURL ?? "")
                    )
                }
            }
        }
    }

    private func profileLinkRow(title: String, value: String, icon: String, tint: Color, url: URL?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not provided" : value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if let url {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 5. Quick Actions
    private var quickActionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("PORTFOLIO DISPATCH")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        copyProfileShareLink()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copy Public Link")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        showingPublicProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Recruiter View")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
        }
    }

    private func copyProfileShareLink() {
        let link = student?.portfolioURL.isEmpty == false ? student!.portfolioURL : "https://careerledger.app/\(student?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "student")"
        #if canImport(UIKit)
        UIPasteboard.general.string = link
        #endif
        copyFeedbackMessage = "Public link copied to clipboard:\n\(link)"
        showingCopyAlert = true
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
            copyFeedbackMessage = "Could not generate PDF: \(error.localizedDescription)"
            showingCopyAlert = true
        }
        isGeneratingPDF = false
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Student.self, Semester.self, Subject.self, Project.self, Achievement.self, Certificate.self], inMemory: true)
}
