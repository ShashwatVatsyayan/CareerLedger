import Foundation

public enum DuplicateResolution: String, CaseIterable, Identifiable, Codable, Sendable {
    case keepExisting = "Keep Existing"
    case replace = "Replace / Update"
    case importAnyway = "Import Anyway"

    public var id: String { rawValue }
}

public struct ExtractedProfile: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var fullName: String = ""
    public var headline: String = ""
    public var bio: String = ""
    public var university: String = ""
    public var githubURL: String = ""
    public var linkedinURL: String = ""

    public init(
        fullName: String = "",
        headline: String = "",
        bio: String = "",
        university: String = "",
        githubURL: String = "",
        linkedinURL: String = ""
    ) {
        self.fullName = fullName
        self.headline = headline
        self.bio = bio
        self.university = university
        self.githubURL = githubURL
        self.linkedinURL = linkedinURL
    }
}

public struct ExtractedEducation: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var isPossibleDuplicate: Bool = false
    public var duplicateResolution: DuplicateResolution = .importAnyway
    public var institution: String = ""
    public var degree: String = ""
    public var field: String = ""
    public var startDate: String = ""
    public var endDate: String = ""
    public var grade: String = ""

    public init(
        institution: String = "",
        degree: String = "",
        field: String = "",
        startDate: String = "",
        endDate: String = "",
        grade: String = ""
    ) {
        self.institution = institution
        self.degree = degree
        self.field = field
        self.startDate = startDate
        self.endDate = endDate
        self.grade = grade
    }
}

public struct ExtractedProject: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var isPossibleDuplicate: Bool = false
    public var duplicateResolution: DuplicateResolution = .importAnyway
    public var existingRecordId: UUID? = nil
    public var title: String = ""
    public var description: String = ""
    public var technologies: String = ""
    public var githubURL: String = ""
    public var demoURL: String = ""

    public init(
        title: String = "",
        description: String = "",
        technologies: String = "",
        githubURL: String = "",
        demoURL: String = ""
    ) {
        self.title = title
        self.description = description
        self.technologies = technologies
        self.githubURL = githubURL
        self.demoURL = demoURL
    }
}

public struct ExtractedAchievement: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var isPossibleDuplicate: Bool = false
    public var duplicateResolution: DuplicateResolution = .importAnyway
    public var existingRecordId: UUID? = nil
    public var title: String = ""
    public var organization: String = ""
    public var description: String = ""
    public var date: String = ""
    public var evidenceURL: String = ""

    public init(
        title: String = "",
        organization: String = "",
        description: String = "",
        date: String = "",
        evidenceURL: String = ""
    ) {
        self.title = title
        self.organization = organization
        self.description = description
        self.date = date
        self.evidenceURL = evidenceURL
    }
}

public struct ExtractedCertificate: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var isPossibleDuplicate: Bool = false
    public var duplicateResolution: DuplicateResolution = .importAnyway
    public var existingRecordId: UUID? = nil
    public var title: String = ""
    public var issuer: String = ""
    public var credentialID: String = ""
    public var issueDate: String = ""
    public var verificationURL: String = ""

    public init(
        title: String = "",
        issuer: String = "",
        credentialID: String = "",
        issueDate: String = "",
        verificationURL: String = ""
    ) {
        self.title = title
        self.issuer = issuer
        self.credentialID = credentialID
        self.issueDate = issueDate
        self.verificationURL = verificationURL
    }
}

public struct ExtractedExperience: Codable, Sendable, Identifiable {
    public var id = UUID()
    public var isSelected: Bool = true
    public var isPossibleDuplicate: Bool = false
    public var duplicateResolution: DuplicateResolution = .importAnyway
    public var existingRecordId: UUID? = nil
    public var organization: String = ""
    public var role: String = ""
    public var startDate: String = ""
    public var endDate: String = ""
    public var description: String = ""

    public init(
        organization: String = "",
        role: String = "",
        startDate: String = "",
        endDate: String = "",
        description: String = ""
    ) {
        self.organization = organization
        self.role = role
        self.startDate = startDate
        self.endDate = endDate
        self.description = description
    }
}

public struct ExtractedCareerData: Codable, Sendable {
    public var profile: ExtractedProfile
    public var education: [ExtractedEducation]
    public var projects: [ExtractedProject]
    public var achievements: [ExtractedAchievement]
    public var certificates: [ExtractedCertificate]
    public var experience: [ExtractedExperience]

    public init(
        profile: ExtractedProfile = ExtractedProfile(),
        education: [ExtractedEducation] = [],
        projects: [ExtractedProject] = [],
        achievements: [ExtractedAchievement] = [],
        certificates: [ExtractedCertificate] = [],
        experience: [ExtractedExperience] = []
    ) {
        self.profile = profile
        self.education = education
        self.projects = projects
        self.achievements = achievements
        self.certificates = certificates
        self.experience = experience
    }

    public var totalRecordsCount: Int {
        (profile.isSelected ? 1 : 0) +
        education.filter { $0.isSelected }.count +
        projects.filter { $0.isSelected }.count +
        achievements.filter { $0.isSelected }.count +
        certificates.filter { $0.isSelected }.count +
        experience.filter { $0.isSelected }.count
    }
}

public struct ImportSummary: Sendable {
    public let profileUpdated: Bool
    public let educationImported: Int
    public let projectsImported: Int
    public let achievementsImported: Int
    public let certificatesImported: Int
    public let experienceImported: Int

    public var totalImported: Int {
        (profileUpdated ? 1 : 0) + educationImported + projectsImported + achievementsImported + certificatesImported + experienceImported
    }
}
