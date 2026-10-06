import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SmartCareerImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingProjects: [Project]
    @Query private var existingCertificates: [Certificate]
    @Query private var existingAchievements: [Achievement]

    enum ImportStep {
        case selectDocument
        case processing
        case review
        case success(ImportSummary)
        case error(String)
    }

    @State private var currentStep: ImportStep = .selectDocument
    @State private var showingFilePicker = false
    @State private var extractedData: ExtractedCareerData = ExtractedCareerData()
    @State private var selectedFileName: String = ""
    @State private var processingStatusText: String = "Reading document..."
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMetalBackgroundView(showFluidWaves: true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case .selectDocument:
                            selectDocumentView
                        case .processing:
                            processingView
                        case .review:
                            reviewDataView
                        case .success(let summary):
                            successView(summary: summary)
                        case .error(let msg):
                            errorView(message: msg)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 680)
                }
            }
            .navigationTitle("Import Career Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first else { return }
                    startImportProcess(url: fileURL)
                case .failure(let err):
                    currentStep = .error(err.localizedDescription)
                }
            }
        }
    }

    // MARK: - Step 1: Select Document
    private var selectDocumentView: some View {
        VStack(spacing: 22) {
            // Hero Banner
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.18))
                        .frame(width: 86, height: 86)
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.75, blue: 1.0), Color(red: 0.25, green: 0.45, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text("Smart Career Import")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Upload your resume to automatically extract and populate your verified career ledger, projects, education, and certificates.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.70, green: 0.72, blue: 0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 10)

            // Upload Box
            Button {
                showingFilePicker = true
            } label: {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))

                    VStack(spacing: 4) {
                        Text("Select Resume PDF")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Supports digital PDF documents")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.60, green: 0.62, blue: 0.68))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Local On-Device AI Extraction")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.85, green: 0.95, blue: 0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0.09, green: 0.09, blue: 0.12).opacity(0.9))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        }
                )
            }
            .buttonStyle(.plain)

            // Quick Sample Resume Button for Testing
            Button {
                loadSampleResume()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.95))
                    Text("Try with Sample Resume (John Doe)")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.90, green: 0.92, blue: 0.98))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            // Free Tier & Data Safety Note
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Privacy & Storage Optimized")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text("Extracted on-device and structured directly into your secure Supabase database. Uploaded resume files are never permanently stored in cloud storage without your permission.")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.65, green: 0.68, blue: 0.75))
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    // MARK: - Step 2: Processing
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ProgressView()
                .controlSize(.large)
                .tint(Color(red: 0.45, green: 0.75, blue: 1.0))

            VStack(spacing: 8) {
                Text(processingStatusText)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(selectedFileName)
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.60, green: 0.62, blue: 0.68))
            }

            Spacer(minLength: 40)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Step 3: Review Data
    private var reviewDataView: some View {
        VStack(spacing: 22) {
            // Header summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Extracted Records")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Edit any details below and uncheck items you do not wish to import.")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.70, green: 0.72, blue: 0.78))
                }
                Spacer()
            }

            // Summary Badges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    badgeView(title: "Profile", count: extractedData.profile.isSelected ? 1 : 0, color: .blue)
                    badgeView(title: "Education", count: extractedData.education.filter { $0.isSelected }.count, color: .purple)
                    badgeView(title: "Projects", count: extractedData.projects.filter { $0.isSelected }.count, color: .teal)
                    badgeView(title: "Certificates", count: extractedData.certificates.filter { $0.isSelected }.count, color: .orange)
                    badgeView(title: "Experience", count: extractedData.experience.filter { $0.isSelected }.count, color: .indigo)
                    badgeView(title: "Achievements", count: extractedData.achievements.filter { $0.isSelected }.count, color: .green)
                }
            }

            // Profile Card
            profileReviewCard

            // Projects Section
            if !extractedData.projects.isEmpty {
                projectsReviewSection
            }

            // Education Section
            if !extractedData.education.isEmpty {
                educationReviewSection
            }

            // Experience Section
            if !extractedData.experience.isEmpty {
                experienceReviewSection
            }

            // Certificates Section
            if !extractedData.certificates.isEmpty {
                certificatesReviewSection
            }

            // Achievements Section
            if !extractedData.achievements.isEmpty {
                achievementsReviewSection
            }

            // Action Buttons
            VStack(spacing: 12) {
                LiquidMetalButton(
                    label: isSaving ? "Saving to Supabase..." : "Confirm & Import (\(extractedData.totalRecordsCount) records)",
                    icon: isSaving ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill",
                    height: 52
                ) {
                    saveConfirmedRecords()
                }
                .disabled(isSaving || extractedData.totalRecordsCount == 0)

                Button("Choose Another Document") {
                    currentStep = .selectDocument
                }
                .font(.footnote)
                .foregroundStyle(Color(red: 0.65, green: 0.68, blue: 0.75))
                .padding(.top, 4)
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Profile Card
    private var profileReviewCard: some View {
        sectionContainer(title: "Personal Profile", systemImage: "person.crop.circle.fill", isSelected: $extractedData.profile.isSelected) {
            VStack(spacing: 12) {
                reviewTextField(label: "Full Name", text: $extractedData.profile.fullName)
                reviewTextField(label: "Headline", text: $extractedData.profile.headline)
                reviewTextField(label: "University / Institution", text: $extractedData.profile.university)
                reviewTextField(label: "Bio / Summary", text: $extractedData.profile.bio, isMultiLine: true)
                reviewTextField(label: "GitHub URL", text: $extractedData.profile.githubURL)
                reviewTextField(label: "LinkedIn URL", text: $extractedData.profile.linkedinURL)
            }
        }
    }

    // MARK: - Projects Section
    private var projectsReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Projects (\(extractedData.projects.count))", systemImage: "cube.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            ForEach($extractedData.projects) { $project in
                itemContainer(
                    title: project.title.isEmpty ? "Untitled Project" : project.title,
                    isSelected: $project.isSelected,
                    isDuplicate: project.isPossibleDuplicate,
                    resolution: $project.duplicateResolution
                ) {
                    VStack(spacing: 10) {
                        reviewTextField(label: "Title", text: $project.title)
                        reviewTextField(label: "Description", text: $project.description, isMultiLine: true)
                        reviewTextField(label: "Technologies", text: $project.technologies)
                        reviewTextField(label: "GitHub URL", text: $project.githubURL)
                        reviewTextField(label: "Demo URL", text: $project.demoURL)
                    }
                }
            }
        }
    }

    // MARK: - Education Section
    private var educationReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Education (\(extractedData.education.count))", systemImage: "graduationcap.fill")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach($extractedData.education) { $edu in
                itemContainer(
                    title: edu.degree.isEmpty ? "Education Record" : edu.degree,
                    isSelected: $edu.isSelected,
                    isDuplicate: edu.isPossibleDuplicate,
                    resolution: $edu.duplicateResolution
                ) {
                    VStack(spacing: 10) {
                        reviewTextField(label: "Institution", text: $edu.institution)
                        reviewTextField(label: "Degree", text: $edu.degree)
                        reviewTextField(label: "Field of Study", text: $edu.field)
                        reviewTextField(label: "Grade / CGPA", text: $edu.grade)
                    }
                }
            }
        }
    }

    // MARK: - Experience Section
    private var experienceReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Experience (\(extractedData.experience.count))", systemImage: "briefcase.fill")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach($extractedData.experience) { $exp in
                itemContainer(
                    title: exp.role.isEmpty ? "Experience Record" : exp.role,
                    isSelected: $exp.isSelected,
                    isDuplicate: exp.isPossibleDuplicate,
                    resolution: $exp.duplicateResolution
                ) {
                    VStack(spacing: 10) {
                        reviewTextField(label: "Role", text: $exp.role)
                        reviewTextField(label: "Organization / Company", text: $exp.organization)
                        reviewTextField(label: "Description", text: $exp.description, isMultiLine: true)
                    }
                }
            }
        }
    }

    // MARK: - Certificates Section
    private var certificatesReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Certificates (\(extractedData.certificates.count))", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach($extractedData.certificates) { $cert in
                itemContainer(
                    title: cert.title.isEmpty ? "Certificate Record" : cert.title,
                    isSelected: $cert.isSelected,
                    isDuplicate: cert.isPossibleDuplicate,
                    resolution: $cert.duplicateResolution
                ) {
                    VStack(spacing: 10) {
                        reviewTextField(label: "Title", text: $cert.title)
                        reviewTextField(label: "Issuer", text: $cert.issuer)
                        reviewTextField(label: "Credential ID", text: $cert.credentialID)
                        reviewTextField(label: "Verification URL", text: $cert.verificationURL)
                    }
                }
            }
        }
    }

    // MARK: - Achievements Section
    private var achievementsReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Achievements (\(extractedData.achievements.count))", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach($extractedData.achievements) { $ach in
                itemContainer(
                    title: ach.title.isEmpty ? "Achievement Record" : ach.title,
                    isSelected: $ach.isSelected,
                    isDuplicate: ach.isPossibleDuplicate,
                    resolution: $ach.duplicateResolution
                ) {
                    VStack(spacing: 10) {
                        reviewTextField(label: "Title", text: $ach.title)
                        reviewTextField(label: "Organization", text: $ach.organization)
                        reviewTextField(label: "Description", text: $ach.description, isMultiLine: true)
                        reviewTextField(label: "Evidence URL", text: $ach.evidenceURL)
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Success View
    private func successView(summary: ImportSummary) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
            }

            VStack(spacing: 8) {
                Text("Career Data Imported!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Successfully saved to your Career Ledger cloud database and synced locally.")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.70, green: 0.72, blue: 0.78))
                    .multilineTextAlignment(.center)
            }

            // Summary Breakdown
            VStack(spacing: 12) {
                if summary.profileUpdated {
                    summaryRow(icon: "person.fill", label: "Profile Updated", value: "✓")
                }
                if summary.projectsImported > 0 {
                    summaryRow(icon: "cube.fill", label: "Projects Saved", value: "\(summary.projectsImported)")
                }
                if summary.educationImported > 0 {
                    summaryRow(icon: "graduationcap.fill", label: "Education Added", value: "\(summary.educationImported)")
                }
                if summary.certificatesImported > 0 {
                    summaryRow(icon: "checkmark.seal.fill", label: "Certificates Recorded", value: "\(summary.certificatesImported)")
                }
                if summary.experienceImported > 0 {
                    summaryRow(icon: "briefcase.fill", label: "Experience Recorded", value: "\(summary.experienceImported)")
                }
                if summary.achievementsImported > 0 {
                    summaryRow(icon: "trophy.fill", label: "Achievements Added", value: "\(summary.achievementsImported)")
                }
            }
            .padding(18)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }

            LiquidMetalButton(
                label: "Return to Dashboard",
                icon: "arrow.left.circle.fill",
                height: 50
            ) {
                dismiss()
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Step 5: Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Import Notice")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.85, green: 0.85, blue: 0.90))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Another File") {
                currentStep = .selectDocument
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            .padding(.top, 10)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Reusable UI Components
    private func badgeView(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color(red: 0.70, green: 0.72, blue: 0.78))
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay {
            Capsule().strokeBorder(color.opacity(0.25), lineWidth: 0.8)
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
        }
    }

    private func sectionContainer<Content: View>(
        title: String,
        systemImage: String,
        isSelected: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle(isOn: isSelected) {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
            }

            if isSelected.wrappedValue {
                content()
            }
        }
        .padding(18)
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private func itemContainer<Content: View>(
        title: String,
        isSelected: Binding<Bool>,
        isDuplicate: Bool,
        resolution: Binding<DuplicateResolution>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Button {
                    isSelected.wrappedValue.toggle()
                } label: {
                    Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected.wrappedValue ? Color.blue : Color.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                if isDuplicate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Possible duplicate")
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            if isDuplicate && isSelected.wrappedValue {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action for existing match:")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.65, green: 0.68, blue: 0.75))

                    Picker("Duplicate Resolution", selection: resolution) {
                        ForEach(DuplicateResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 2)
            }

            if isSelected.wrappedValue {
                content()
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isDuplicate ? Color.orange.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func reviewTextField(label: String, text: Binding<String>, isMultiLine: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color(red: 0.65, green: 0.68, blue: 0.75))

            if isMultiLine {
                TextField(label, text: text, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
                    .foregroundStyle(.white)
            } else {
                TextField(label, text: text)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Actions
    private func startImportProcess(url: URL) {
        selectedFileName = url.lastPathComponent
        currentStep = .processing
        processingStatusText = "Reading document..."

        Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    processingStatusText = "Extracting career information..."
                }

                let analyzed = try await CareerImportService.shared.extractAndAnalyze(
                    documentURL: url,
                    existingProjects: existingProjects,
                    existingCertificates: existingCertificates,
                    existingAchievements: existingAchievements
                )

                await MainActor.run {
                    self.extractedData = analyzed
                    self.currentStep = .review
                }
            } catch {
                await MainActor.run {
                    self.currentStep = .error(error.localizedDescription)
                }
            }
        }
    }

    private func loadSampleResume() {
        let sampleURL = URL(fileURLWithPath: "/Users/cu_student35/Documents/24BCS12850_Shashwat/Project/CareerLedger/sample_resume.pdf")
        if FileManager.default.fileExists(atPath: sampleURL.path) {
            startImportProcess(url: sampleURL)
        } else {
            let sampleText = """
            Name: John Doe
            University: Chandigarh University
            Education: B.E. Computer Science Engineering
            Projects: Career Ledger, Aegis AI
            Skills: Swift, SwiftUI, Python
            Experience: Software Developer Intern
            Certificates: Google Cloud Certificate
            """
            selectedFileName = "Sample_Resume_John_Doe.pdf"
            currentStep = .processing
            processingStatusText = "Extracting career information..."

            Task {
                try await Task.sleep(nanoseconds: 300_000_000)
                var data = SmartResumeExtractor.shared.extract(from: sampleText)

                // Detect duplicates against existing projects & certificates
                for i in 0..<data.projects.count {
                    let key = data.projects[i].title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if let match = existingProjects.first(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }) {
                        data.projects[i].isPossibleDuplicate = true
                        data.projects[i].existingRecordId = match.id
                        data.projects[i].duplicateResolution = .keepExisting
                    }
                }

                for i in 0..<data.certificates.count {
                    let key = data.certificates[i].title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if let match = existingCertificates.first(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }) {
                        data.certificates[i].isPossibleDuplicate = true
                        data.certificates[i].existingRecordId = match.id
                        data.certificates[i].duplicateResolution = .keepExisting
                    }
                }

                await MainActor.run {
                    self.extractedData = data
                    self.currentStep = .review
                }
            }
        }
    }

    private func saveConfirmedRecords() {
        isSaving = true

        Task {
            do {
                let summary = try await CareerImportService.shared.saveConfirmedData(
                    data: extractedData,
                    modelContext: modelContext
                )
                await MainActor.run {
                    self.isSaving = false
                    self.currentStep = .success(summary)
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.currentStep = .error(error.localizedDescription)
                }
            }
        }
    }
}
