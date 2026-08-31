import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    var technologies: String
    var githubURL: String
    var demoURL: String
    var verificationStatusRaw: String
    var date: Date
    var createdAt: Date

    var verificationStatus: VerificationStatus {
        get { VerificationStatus(rawValue: verificationStatusRaw) ?? .selfReported }
        set { verificationStatusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        technologies: String,
        githubURL: String = "",
        demoURL: String = "",
        verificationStatus: VerificationStatus = .selfReported,
        date: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = description
        self.technologies = technologies
        self.githubURL = githubURL
        self.demoURL = demoURL
        self.verificationStatusRaw = verificationStatus.rawValue
        self.date = date
        self.createdAt = createdAt
    }
}
