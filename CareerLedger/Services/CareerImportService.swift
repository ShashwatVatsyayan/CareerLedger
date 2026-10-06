import Foundation
import SwiftData
import Supabase

final class CareerImportService: @unchecked Sendable {
    static let shared = CareerImportService()

    private init() {}

    // MARK: - Extract and Detect Duplicates
    func extractAndAnalyze(
        documentURL: URL,
        existingProjects: [Project] = [],
        existingCertificates: [Certificate] = [],
        existingAchievements: [Achievement] = []
    ) async throws -> ExtractedCareerData {
        var data = try await SmartResumeExtractor.shared.extract(from: documentURL)

        // Fetch user records from Supabase only with a validated active session token
        var remoteProjectTitles: [String: UUID] = [:]
        var remoteCertTitles: [String: UUID] = [:]
        var remoteAchievementTitles: [String: UUID] = [:]

        if let (_, userUUID) = try? SupabaseManager.shared.validateActiveSession() {
            // Strictly project only the required fields: "id, title" to minimize payload exposure
            struct TitleRecord: Decodable {
                let id: UUID
                let title: String
            }
            if let projects: [TitleRecord] = try? await SupabaseManager.shared.client
                .from("projects")
                .select("id, title")
                .eq("user_id", value: userUUID)
                .execute()
                .value {
                for p in projects {
                    remoteProjectTitles[p.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = p.id
                }
            }

            if let certs: [TitleRecord] = try? await SupabaseManager.shared.client
                .from("certificates")
                .select("id, title")
                .eq("user_id", value: userUUID)
                .execute()
                .value {
                for c in certs {
                    remoteCertTitles[c.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = c.id
                }
            }

            if let achs: [TitleRecord] = try? await SupabaseManager.shared.client
                .from("achievements")
                .select("id, title")
                .eq("user_id", value: userUUID)
                .execute()
                .value {
                for a in achs {
                    remoteAchievementTitles[a.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = a.id
                }
            }
        }

        // Duplicate Detection for Projects
        for i in 0..<data.projects.count {
            let key = data.projects[i].title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let matchedUUID = remoteProjectTitles[key] {
                data.projects[i].isPossibleDuplicate = true
                data.projects[i].existingRecordId = matchedUUID
                data.projects[i].duplicateResolution = .keepExisting
            } else if let localMatch = existingProjects.first(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }) {
                data.projects[i].isPossibleDuplicate = true
                data.projects[i].existingRecordId = localMatch.id
                data.projects[i].duplicateResolution = .keepExisting
            }
        }

        // Duplicate Detection for Certificates
        for i in 0..<data.certificates.count {
            let key = data.certificates[i].title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let matchedUUID = remoteCertTitles[key] {
                data.certificates[i].isPossibleDuplicate = true
                data.certificates[i].existingRecordId = matchedUUID
                data.certificates[i].duplicateResolution = .keepExisting
            } else if let localMatch = existingCertificates.first(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }) {
                data.certificates[i].isPossibleDuplicate = true
                data.certificates[i].existingRecordId = localMatch.id
                data.certificates[i].duplicateResolution = .keepExisting
            }
        }

        // Duplicate Detection for Achievements
        for i in 0..<data.achievements.count {
            let key = data.achievements[i].title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let matchedUUID = remoteAchievementTitles[key] {
                data.achievements[i].isPossibleDuplicate = true
                data.achievements[i].existingRecordId = matchedUUID
                data.achievements[i].duplicateResolution = .keepExisting
            } else if let localMatch = existingAchievements.first(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }) {
                data.achievements[i].isPossibleDuplicate = true
                data.achievements[i].existingRecordId = localMatch.id
                data.achievements[i].duplicateResolution = .keepExisting
            }
        }

        return data
    }

    // MARK: - Save Confirmed Records
    func saveConfirmedData(
        data: ExtractedCareerData,
        modelContext: ModelContext
    ) async throws -> ImportSummary {
        // Enforce strict authenticated session token validation
        let (_, userUUID) = try SupabaseManager.shared.validateActiveSession()

        let client = SupabaseManager.shared.client

        // 1. Profile Update
        var profileUpdated = false
        if data.profile.isSelected {
            struct ProfileUpdateRow: Encodable {
                let user_id: UUID
                let full_name: String
                let headline: String
                let bio: String
                let university: String
                let github_url: String
                let linkedin_url: String
            }

            let profileRow = ProfileUpdateRow(
                user_id: userUUID,
                full_name: data.profile.fullName,
                headline: data.profile.headline,
                bio: data.profile.bio,
                university: data.profile.university,
                github_url: data.profile.githubURL,
                linkedin_url: data.profile.linkedinURL
            )

            do {
                _ = try await client
                    .from("profiles")
                    .upsert(profileRow, onConflict: "user_id")
                    .execute()
                profileUpdated = true
            } catch {
                _ = try? await client
                    .from("profiles")
                    .insert(profileRow)
                    .execute()
                profileUpdated = true
            }
        }

        // 2. Education Insert
        var eduCount = 0
        struct EducationInsertRow: Encodable {
            let id: UUID
            let user_id: UUID
            let institution: String
            let degree: String
            let field: String
            let grade: String?
        }

        for edu in data.education where edu.isSelected {
            let row = EducationInsertRow(
                id: UUID(),
                user_id: userUUID,
                institution: edu.institution,
                degree: edu.degree,
                field: edu.field,
                grade: edu.grade.isEmpty ? nil : edu.grade
            )
            do {
                _ = try await client.from("education").insert(row).execute()
                eduCount += 1
            } catch {
                #if DEBUG
                print("Notice: Education insert in Supabase: \(error.localizedDescription)")
                #endif
            }
        }

        // 3. Projects Insert / Update
        var projCount = 0
        struct ProjectInsertRow: Encodable {
            let id: UUID
            let user_id: UUID
            let title: String
            let description: String
            let technologies: String
            let github_url: String
            let demo_url: String
        }

        for proj in data.projects where proj.isSelected {
            if proj.isPossibleDuplicate && proj.duplicateResolution == .keepExisting {
                continue
            }

            if proj.isPossibleDuplicate && proj.duplicateResolution == .replace, let existingId = proj.existingRecordId {
                struct ProjectUpdateRow: Encodable {
                    let title: String
                    let description: String
                    let technologies: String
                    let github_url: String
                    let demo_url: String
                }
                let updateRow = ProjectUpdateRow(
                    title: proj.title,
                    description: proj.description,
                    technologies: proj.technologies,
                    github_url: proj.githubURL,
                    demo_url: proj.demoURL
                )
                _ = try? await client
                    .from("projects")
                    .update(updateRow)
                    .eq("id", value: existingId)
                    .eq("user_id", value: userUUID)
                    .execute()
                projCount += 1
            } else {
                let row = ProjectInsertRow(
                    id: UUID(),
                    user_id: userUUID,
                    title: proj.title,
                    description: proj.description,
                    technologies: proj.technologies,
                    github_url: proj.githubURL,
                    demo_url: proj.demoURL
                )
                _ = try? await client.from("projects").insert(row).execute()
                projCount += 1
            }
        }

        // 4. Achievements Insert / Update
        var achCount = 0
        struct AchievementInsertRow: Encodable {
            let id: UUID
            let user_id: UUID
            let title: String
            let organization: String
            let description: String
            let evidence_url: String
        }

        for ach in data.achievements where ach.isSelected {
            if ach.isPossibleDuplicate && ach.duplicateResolution == .keepExisting {
                continue
            }
            let row = AchievementInsertRow(
                id: UUID(),
                user_id: userUUID,
                title: ach.title,
                organization: ach.organization,
                description: ach.description,
                evidence_url: ach.evidenceURL
            )
            _ = try? await client.from("achievements").insert(row).execute()
            achCount += 1
        }

        // 5. Certificates Insert / Update
        var certCount = 0
        struct CertificateInsertRow: Encodable {
            let id: UUID
            let user_id: UUID
            let title: String
            let issuer: String
            let credential_id: String
            let verification_url: String
        }

        for cert in data.certificates where cert.isSelected {
            if cert.isPossibleDuplicate && cert.duplicateResolution == .keepExisting {
                continue
            }
            let row = CertificateInsertRow(
                id: UUID(),
                user_id: userUUID,
                title: cert.title,
                issuer: cert.issuer,
                credential_id: cert.credentialID,
                verification_url: cert.verificationURL
            )
            _ = try? await client.from("certificates").insert(row).execute()
            certCount += 1
        }

        // 6. Experience Insert
        var expCount = 0
        struct ExperienceInsertRow: Encodable {
            let id: UUID
            let user_id: UUID
            let organization: String
            let role: String
            let description: String
        }

        for exp in data.experience where exp.isSelected {
            if exp.isPossibleDuplicate && exp.duplicateResolution == .keepExisting {
                continue
            }
            let row = ExperienceInsertRow(
                id: UUID(),
                user_id: userUUID,
                organization: exp.organization,
                role: exp.role,
                description: exp.description
            )
            _ = try? await client.from("experience").insert(row).execute()
            expCount += 1
        }

        // Sync with local SwiftData so user sees changes immediately
        await MainActor.run {
            syncToLocalSwiftData(data: data, modelContext: modelContext)
        }

        return ImportSummary(
            profileUpdated: profileUpdated,
            educationImported: eduCount,
            projectsImported: projCount,
            achievementsImported: achCount,
            certificatesImported: certCount,
            experienceImported: expCount
        )
    }

    // MARK: - SwiftData Local Mirror
    @MainActor
    private func syncToLocalSwiftData(data: ExtractedCareerData, modelContext: ModelContext) {
        // Sync student profile
        if data.profile.isSelected {
            let students = (try? modelContext.fetch(FetchDescriptor<Student>())) ?? []
            if let student = students.first {
                if !data.profile.fullName.isEmpty { student.name = data.profile.fullName }
                if !data.profile.university.isEmpty { student.university = data.profile.university }
                if !data.profile.bio.isEmpty { student.bio = data.profile.bio }
                if !data.profile.githubURL.isEmpty { student.githubURL = data.profile.githubURL }
                if !data.profile.linkedinURL.isEmpty { student.linkedinURL = data.profile.linkedinURL }
            } else {
                let student = Student(
                    name: data.profile.fullName.isEmpty ? "Student" : data.profile.fullName,
                    course: data.education.first?.degree ?? "Computer Science",
                    university: data.profile.university.isEmpty ? "Chandigarh University" : data.profile.university,
                    email: SupabaseManager.shared.currentUserEmail ?? "student@example.com",
                    bio: data.profile.bio,
                    githubURL: data.profile.githubURL,
                    linkedinURL: data.profile.linkedinURL
                )
                modelContext.insert(student)
            }
        }

        // Sync Projects
        for proj in data.projects where proj.isSelected {
            if proj.isPossibleDuplicate && proj.duplicateResolution == .keepExisting {
                continue
            }

            let existing = (try? modelContext.fetch(FetchDescriptor<Project>())) ?? []
            if let matched = existing.first(where: { $0.name.caseInsensitiveCompare(proj.title) == .orderedSame }) {
                if proj.duplicateResolution == .replace {
                    matched.projectDescription = proj.description
                    matched.technologies = proj.technologies
                    if !proj.githubURL.isEmpty { matched.githubURL = proj.githubURL }
                    if !proj.demoURL.isEmpty { matched.demoURL = proj.demoURL }
                }
            } else {
                let newProj = Project(
                    name: proj.title,
                    description: proj.description,
                    technologies: proj.technologies,
                    githubURL: proj.githubURL,
                    demoURL: proj.demoURL,
                    verificationStatus: .selfReported
                )
                modelContext.insert(newProj)
            }
        }

        // Sync Certificates
        for cert in data.certificates where cert.isSelected {
            if cert.isPossibleDuplicate && cert.duplicateResolution == .keepExisting {
                continue
            }
            let existing = (try? modelContext.fetch(FetchDescriptor<Certificate>())) ?? []
            if !existing.contains(where: { $0.title.caseInsensitiveCompare(cert.title) == .orderedSame }) {
                let newCert = Certificate(
                    title: cert.title,
                    issuer: cert.issuer,
                    credentialID: cert.credentialID,
                    verificationURL: cert.verificationURL
                )
                modelContext.insert(newCert)
            }
        }

        // Sync Achievements
        for ach in data.achievements where ach.isSelected {
            if ach.isPossibleDuplicate && ach.duplicateResolution == .keepExisting {
                continue
            }
            let existing = (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
            if !existing.contains(where: { $0.title.caseInsensitiveCompare(ach.title) == .orderedSame }) {
                let newAch = Achievement(
                    title: ach.title,
                    organization: ach.organization,
                    category: "Technical",
                    description: ach.description,
                    evidenceURL: ach.evidenceURL
                )
                modelContext.insert(newAch)
            }
        }

        try? modelContext.save()
    }
}
