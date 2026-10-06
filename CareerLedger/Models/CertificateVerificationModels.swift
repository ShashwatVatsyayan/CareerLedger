import Foundation
import SwiftUI

// MARK: - Certificate Verification Status
/// Verification status representing the exact authoritative trust level of a credential.
public enum CertificateVerificationStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case notVerified = "NOT_VERIFIED"
    case evidenceProvided = "EVIDENCE_PROVIDED"
    case automaticallyVerified = "AUTOMATICALLY_VERIFIED"
    case issuerVerified = "ISSUER_VERIFIED"
    case disputed = "DISPUTED"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .notVerified:
            return "Not Verified"
        case .evidenceProvided:
            return "Evidence Provided"
        case .automaticallyVerified:
            return "Automatically Verified"
        case .issuerVerified:
            return "Issuer Verified"
        case .disputed:
            return "Disputed"
        }
    }

    public var badgeTitle: String {
        switch self {
        case .notVerified:
            return "NOT VERIFIED"
        case .evidenceProvided:
            return "EVIDENCE PROVIDED"
        case .automaticallyVerified:
            return "AUTOMATICALLY VERIFIED"
        case .issuerVerified:
            return "ISSUER VERIFIED"
        case .disputed:
            return "DISPUTED"
        }
    }

    public var iconName: String {
        switch self {
        case .notVerified:
            return "circle"
        case .evidenceProvided:
            return "doc.text.magnifyingglass"
        case .automaticallyVerified:
            return "checkmark.seal.fill"
        case .issuerVerified:
            return "building.columns.fill"
        case .disputed:
            return "exclamationmark.triangle.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .notVerified:
            return Color.secondary
        case .evidenceProvided:
            return Color.blue
        case .automaticallyVerified:
            return Color.green
        case .issuerVerified:
            return Color.purple
        case .disputed:
            return Color.red
        }
    }

    public var colorDot: String {
        switch self {
        case .notVerified:
            return "⚪"
        case .evidenceProvided:
            return "🔵"
        case .automaticallyVerified:
            return "🟢"
        case .issuerVerified:
            return "🟣"
        case .disputed:
            return "🔴"
        }
    }

    public var detailedExplanation: String {
        switch self {
        case .notVerified:
            return "This credential was recorded manually without supporting documentation or independent issuer confirmation."
        case .evidenceProvided:
            return "A supporting document or certificate image has been uploaded as proof. Career Ledger has preserved the evidence on file, but independent issuer confirmation has not yet occurred."
        case .automaticallyVerified:
            return "Career Ledger independently queried the official issuer's verification portal or API and matched the credential ID, recipient name, and certificate parameters."
        case .issuerVerified:
            return "The issuing university, academy, or organization directly confirmed and signed this credential via an authorized verification mechanism."
        case .disputed:
            return "The official issuer explicitly indicates that this credential is nonexistent, revoked, invalid, or otherwise disputed."
        }
    }

    /// Backwards compatibility converter for legacy raw string representations
    public static func fromLegacy(_ raw: String) -> CertificateVerificationStatus {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "self reported", "not_verified", "not verified", "unverified":
            return .notVerified
        case "evidence provided", "evidence_provided":
            return .evidenceProvided
        case "source verified", "source_verified", "automatically_verified", "automatically verified":
            return .automaticallyVerified
        case "issuer verified", "issuer_verified":
            return .issuerVerified
        case "disputed", "rejected", "revoked":
            return .disputed
        default:
            return .notVerified
        }
    }
}

// MARK: - Verification Details Record
/// Structured metadata describing how and when a certificate was evaluated.
public struct CertificateVerificationRecord: Codable, Sendable {
    public var status: CertificateVerificationStatus
    public var method: String               // e.g. "official_verification_url", "official_api", "issuer_portal", "issuer_confirmation"
    public var verifiedAt: Date?
    public var source: String               // e.g. "https://coursera.org/verify/ABC123XYZ"
    public var matchedFields: [String]      // e.g. ["Credential ID", "Recipient Name", "Issuer", "Issue Date"]
    public var unmatchedFields: [String]
    public var notes: String
    public var authoritativeDomain: String?
    public var isAuthoritativeSource: Bool

    public init(
        status: CertificateVerificationStatus = .notVerified,
        method: String = "",
        verifiedAt: Date? = nil,
        source: String = "",
        matchedFields: [String] = [],
        unmatchedFields: [String] = [],
        notes: String = "",
        authoritativeDomain: String? = nil,
        isAuthoritativeSource: Bool = false
    ) {
        self.status = status
        self.method = method
        self.verifiedAt = verifiedAt
        self.source = source
        self.matchedFields = matchedFields
        self.unmatchedFields = unmatchedFields
        self.notes = notes
        self.authoritativeDomain = authoritativeDomain
        self.isAuthoritativeSource = isAuthoritativeSource
    }

    public static func defaultRecord(for status: CertificateVerificationStatus) -> CertificateVerificationRecord {
        CertificateVerificationRecord(
            status: status,
            method: status == .notVerified ? "manual_entry" : "document_upload",
            verifiedAt: status == .automaticallyVerified || status == .issuerVerified ? Date() : nil,
            source: "",
            matchedFields: [],
            unmatchedFields: [],
            notes: status.detailedExplanation,
            authoritativeDomain: nil,
            isAuthoritativeSource: false
        )
    }

    public func toJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    public static func fromJSONString(_ string: String) -> CertificateVerificationRecord? {
        guard let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CertificateVerificationRecord.self, from: data)
    }
}

// MARK: - Extracted Certificate Details
/// Details parsed from an uploaded evidence document (PDF or image).
public struct ExtractedCertificateDetails: Sendable {
    public var title: String
    public var issuer: String
    public var recipientName: String
    public var credentialID: String
    public var issueDate: Date?
    public var expiryDate: Date?
    public var verificationURL: String
    public var qrCodePayload: String?
    public var rawText: String
    public var confidence: Double

    public init(
        title: String = "",
        issuer: String = "",
        recipientName: String = "",
        credentialID: String = "",
        issueDate: Date? = nil,
        expiryDate: Date? = nil,
        verificationURL: String = "",
        qrCodePayload: String? = nil,
        rawText: String = "",
        confidence: Double = 0.0
    ) {
        self.title = title
        self.issuer = issuer
        self.recipientName = recipientName
        self.credentialID = credentialID
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.verificationURL = verificationURL
        self.qrCodePayload = qrCodePayload
        self.rawText = rawText
        self.confidence = confidence
    }
}

// MARK: - Verification Request & Result
public struct CredentialVerificationRequest: Sendable {
    public let certificateTitle: String
    public let issuer: String
    public let recipientName: String
    public let credentialID: String
    public let verificationURL: String
    public let issueDate: Date?
    public let hasEvidence: Bool

    public init(
        certificateTitle: String,
        issuer: String,
        recipientName: String,
        credentialID: String,
        verificationURL: String,
        issueDate: Date?,
        hasEvidence: Bool
    ) {
        self.certificateTitle = certificateTitle
        self.issuer = issuer
        self.recipientName = recipientName
        self.credentialID = credentialID
        self.verificationURL = verificationURL
        self.issueDate = issueDate
        self.hasEvidence = hasEvidence
    }
}

public struct CredentialVerificationResult: Sendable {
    public let status: CertificateVerificationStatus
    public let method: String
    public let source: String
    public let matchedFields: [String]
    public let unmatchedFields: [String]
    public let notes: String
    public let isAuthoritative: Bool
    public let verifiedAt: Date?

    public init(
        status: CertificateVerificationStatus,
        method: String,
        source: String,
        matchedFields: [String],
        unmatchedFields: [String],
        notes: String,
        isAuthoritative: Bool,
        verifiedAt: Date? = nil
    ) {
        self.status = status
        self.method = method
        self.source = source
        self.matchedFields = matchedFields
        self.unmatchedFields = unmatchedFields
        self.notes = notes
        self.isAuthoritative = isAuthoritative
        self.verifiedAt = verifiedAt
    }
}
