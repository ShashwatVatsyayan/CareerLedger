import Foundation
import SwiftData

enum VerificationStatus: String, CaseIterable, Codable, Identifiable {
    case selfReported = "Self Reported"
    case evidenceProvided = "Evidence Provided"
    case sourceVerified = "Source Verified"
    case issuerVerified = "Issuer Verified"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }
}

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var title: String
    var organization: String
    var date: Date
    var category: String
    var achievementDescription: String
    var credentialID: String
    var evidenceURL: String
    var verificationStatusRaw: String
    var createdAt: Date

    var verificationStatus: VerificationStatus {
        get { VerificationStatus(rawValue: verificationStatusRaw) ?? .selfReported }
        set { verificationStatusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        organization: String,
        date: Date = Date(),
        category: String,
        description: String,
        credentialID: String = "",
        evidenceURL: String = "",
        verificationStatus: VerificationStatus = .selfReported,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.organization = organization
        self.date = date
        self.category = category
        self.achievementDescription = description
        self.credentialID = credentialID
        self.evidenceURL = evidenceURL
        self.verificationStatusRaw = verificationStatus.rawValue
        self.createdAt = createdAt
    }
}
