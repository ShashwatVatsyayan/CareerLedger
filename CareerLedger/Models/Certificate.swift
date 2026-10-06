import Foundation
import SwiftData

@Model
final class Certificate {
    @Attribute(.unique) var id: UUID
    var userID: UUID?
    var title: String
    var issuer: String
    var issueDate: Date
    var credentialID: String
    var verificationURL: String
    var evidenceURLRaw: String?
    var verificationStatusRaw: String
    var verificationMethodRaw: String?
    var verifiedAt: Date?
    var verificationSourceRaw: String?
    var verificationDetailsRaw: String?
    var createdAt: Date
    var updatedAtRaw: Date?

    var evidenceURL: String {
        get { evidenceURLRaw ?? "" }
        set { evidenceURLRaw = newValue }
    }

    var verificationMethod: String {
        get { verificationMethodRaw ?? "" }
        set { verificationMethodRaw = newValue }
    }

    var verificationSource: String {
        get { verificationSourceRaw ?? "" }
        set { verificationSourceRaw = newValue }
    }

    var verificationDetails: String {
        get { verificationDetailsRaw ?? "" }
        set { verificationDetailsRaw = newValue }
    }

    var updatedAt: Date {
        get { updatedAtRaw ?? createdAt }
        set { updatedAtRaw = newValue }
    }

    var verificationStatus: CertificateVerificationStatus {
        get {
            CertificateVerificationStatus(rawValue: verificationStatusRaw)
                ?? CertificateVerificationStatus.fromLegacy(verificationStatusRaw)
        }
        set {
            verificationStatusRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var parsedVerificationRecord: CertificateVerificationRecord {
        if !verificationDetails.isEmpty,
           let record = CertificateVerificationRecord.fromJSONString(verificationDetails) {
            return record
        }
        return CertificateVerificationRecord(
            status: verificationStatus,
            method: verificationMethod,
            verifiedAt: verifiedAt,
            source: verificationSource.isEmpty ? verificationURL : verificationSource,
            matchedFields: verificationStatus == .automaticallyVerified ? ["Credential ID", "Recipient Name", "Issuer", "Issue Date"] : [],
            unmatchedFields: [],
            notes: verificationStatus.detailedExplanation,
            authoritativeDomain: URL(string: verificationURL)?.host(),
            isAuthoritativeSource: verificationStatus == .automaticallyVerified || verificationStatus == .issuerVerified
        )
    }

    init(
        id: UUID = UUID(),
        userID: UUID? = nil,
        title: String,
        issuer: String,
        issueDate: Date = Date(),
        credentialID: String = "",
        verificationURL: String = "",
        evidenceURL: String = "",
        verificationStatus: CertificateVerificationStatus = .notVerified,
        verificationMethod: String = "",
        verifiedAt: Date? = nil,
        verificationSource: String = "",
        verificationDetails: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.issuer = issuer
        self.issueDate = issueDate
        self.credentialID = credentialID
        self.verificationURL = verificationURL
        self.evidenceURLRaw = evidenceURL.isEmpty ? nil : evidenceURL
        self.verificationStatusRaw = verificationStatus.rawValue
        self.verificationMethodRaw = verificationMethod.isEmpty ? nil : verificationMethod
        self.verifiedAt = verifiedAt
        self.verificationSourceRaw = verificationSource.isEmpty ? nil : verificationSource
        self.verificationDetailsRaw = verificationDetails.isEmpty ? nil : verificationDetails
        self.createdAt = createdAt
        self.updatedAtRaw = updatedAt
    }

    /// Convenience initializer for legacy callers passing VerificationStatus
    convenience init(
        id: UUID = UUID(),
        title: String,
        issuer: String,
        issueDate: Date = Date(),
        credentialID: String,
        verificationURL: String = "",
        verificationStatus: VerificationStatus,
        createdAt: Date = Date()
    ) {
        let mappedStatus: CertificateVerificationStatus
        switch verificationStatus {
        case .selfReported:
            mappedStatus = .notVerified
        case .evidenceProvided:
            mappedStatus = .evidenceProvided
        case .sourceVerified:
            mappedStatus = .automaticallyVerified
        case .issuerVerified:
            mappedStatus = .issuerVerified
        }

        self.init(
            id: id,
            userID: nil,
            title: title,
            issuer: issuer,
            issueDate: issueDate,
            credentialID: credentialID,
            verificationURL: verificationURL,
            evidenceURL: "",
            verificationStatus: mappedStatus,
            verificationMethod: mappedStatus == .automaticallyVerified ? "official_verification_url" : (mappedStatus == .issuerVerified ? "issuer_portal" : ""),
            verifiedAt: (mappedStatus == .automaticallyVerified || mappedStatus == .issuerVerified) ? Date() : nil,
            verificationSource: verificationURL,
            verificationDetails: "",
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
