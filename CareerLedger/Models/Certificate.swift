import Foundation
import SwiftData

@Model
final class Certificate {
    @Attribute(.unique) var id: UUID
    var title: String
    var issuer: String
    var issueDate: Date
    var credentialID: String
    var verificationURL: String
    var verificationStatusRaw: String
    var createdAt: Date

    var verificationStatus: VerificationStatus {
        get { VerificationStatus(rawValue: verificationStatusRaw) ?? .selfReported }
        set { verificationStatusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        issuer: String,
        issueDate: Date = Date(),
        credentialID: String,
        verificationURL: String = "",
        verificationStatus: VerificationStatus = .selfReported,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.issuer = issuer
        self.issueDate = issueDate
        self.credentialID = credentialID
        self.verificationURL = verificationURL
        self.verificationStatusRaw = verificationStatus.rawValue
        self.createdAt = createdAt
    }
}
