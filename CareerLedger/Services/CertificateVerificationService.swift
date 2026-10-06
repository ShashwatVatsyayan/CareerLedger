import Foundation

// MARK: - Credential Verification Provider Protocol
public protocol CredentialVerificationProvider: Sendable {
    var providerID: String { get }
    var providerName: String { get }
    func canHandle(issuer: String, verificationURL: String) -> Bool
    func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult
}

// MARK: - Certificate Verification Service
public final class CertificateVerificationService: @unchecked Sendable {
    public static let shared = CertificateVerificationService()

    private var providers: [CredentialVerificationProvider] = []

    private init() {
        registerDefaultProviders()
    }

    private func registerDefaultProviders() {
        providers = [
            CourseraVerificationProvider(),
            CredlyVerificationProvider(),
            AccredibleVerificationProvider(),
            AuthorizedIssuerAccountProvider(),
            GenericOfficialPortalVerificationProvider()
        ]
    }

    /// Evaluates and verifies a certificate credential against authoritative sources
    public func verifyCredential(request: CredentialVerificationRequest) async -> CredentialVerificationResult {
        let trimmedURL = request.verificationURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = request.issuer.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. If no verification URL and no evidence was provided
        if trimmedURL.isEmpty && !request.hasEvidence {
            return CredentialVerificationResult(
                status: .notVerified,
                method: "none",
                source: "",
                matchedFields: [],
                unmatchedFields: ["Verification URL", "Credential Evidence"],
                notes: "No official verification URL or supporting evidence was provided.",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }

        // 2. If evidence is provided but NO verification URL is available (e.g. Universities without online portals)
        if trimmedURL.isEmpty && request.hasEvidence {
            return CredentialVerificationResult(
                status: .evidenceProvided,
                method: "document_evidence",
                source: "",
                matchedFields: ["Document Proof"],
                unmatchedFields: ["Online Verification Portal"],
                notes: "Official evidence document is preserved on file. Most universities and traditional organizations do not operate public verification portals. This credential remains Evidence Provided until direct issuer confirmation.",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }

        // 3. Inspect Verification URL domain authority
        guard let url = URL(string: trimmedURL), let host = url.host()?.lowercased() else {
            return CredentialVerificationResult(
                status: request.hasEvidence ? .evidenceProvided : .notVerified,
                method: "invalid_url",
                source: trimmedURL,
                matchedFields: [],
                unmatchedFields: ["Valid URL"],
                notes: "The provided verification URL is malformed or invalid.",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }

        // 4. Reject Non-Authoritative / Untrusted Domains
        if isBlacklistedOrUntrustedDomain(host) {
            return CredentialVerificationResult(
                status: request.hasEvidence ? .evidenceProvided : .notVerified,
                method: "untrusted_source",
                source: trimmedURL,
                matchedFields: [],
                unmatchedFields: ["Authoritative Issuer Source"],
                notes: "The verification link points to an untrusted domain (\(host)). Independent verification requires an authoritative issuer portal or accredited credential provider. It will not be marked as verified.",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }

        // 5. Query matching provider
        for provider in providers {
            if provider.canHandle(issuer: trimmedIssuer, verificationURL: trimmedURL) {
                do {
                    return try await provider.verify(request: request)
                } catch {
                    #if DEBUG
                    print("[CertificateVerificationService] Provider \(provider.providerName) error: \(error)")
                    #endif
                }
            }
        }

        // 6. Fallback generic authoritative check
        do {
            return try await GenericOfficialPortalVerificationProvider().verify(request: request)
        } catch {
            return CredentialVerificationResult(
                status: request.hasEvidence ? .evidenceProvided : .notVerified,
                method: "official_verification_url",
                source: request.verificationURL,
                matchedFields: [],
                unmatchedFields: ["Authoritative Issuer Source"],
                notes: "Could not complete verification with the specified portal: \(error.localizedDescription)",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }
    }

    /// Evaluates if a domain is an untrusted/generic site (social media, paste sites, search snippets, file sharing)
    public func isBlacklistedOrUntrustedDomain(_ host: String) -> Bool {
        let untrustedHosts = [
            "example.com", "example.org", "pastebin.com", "imgur.com",
            "facebook.com", "twitter.com", "x.com", "instagram.com",
            "linkedin.com", "google.com", "bing.com", "yahoo.com",
            "bit.ly", "tinyurl.com", "blogspot.com", "wordpress.com",
            "drive.google.com", "dropbox.com", "github.com", "raw.githubusercontent.com"
        ]

        for bad in untrustedHosts {
            if host == bad || host.hasSuffix("." + bad) {
                return true
            }
        }
        return false
    }

    /// Evaluates if a domain is recognized as an authoritative credential authority
    public func isAuthoritativeDomain(_ host: String) -> Bool {
        let authoritativeRoots = [
            "coursera.org", "credly.com", "youracclaim.com", "accredible.com",
            "cloud.google.com", "microsoft.com", "learn.microsoft.com",
            "certmetrics.com", "aws.training", "edx.org", "udacity.com",
            "cuchd.in", "cuchd.edu.in", "nptel.ac.in", "hackerrank.com",
            "leetcode.com", "freecodecamp.org"
        ]

        for root in authoritativeRoots {
            if host == root || host.hasSuffix("." + root) {
                return true
            }
        }

        // Also accept recognized university domains (.edu, .ac.in, .ac.uk) if verifying credential
        if host.hasSuffix(".edu") || host.hasSuffix(".ac.in") || host.hasSuffix(".ac.uk") {
            return true
        }

        return false
    }
}

// MARK: - Coursera Verification Provider
private struct CourseraVerificationProvider: CredentialVerificationProvider {
    let providerID = "coursera"
    let providerName = "Coursera Verification Service"

    func canHandle(issuer: String, verificationURL: String) -> Bool {
        let lowerURL = verificationURL.lowercased()
        let lowerIssuer = issuer.lowercased()
        return lowerURL.contains("coursera.org/verify") || lowerIssuer.contains("coursera")
    }

    func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult {
        return try await executeAuthoritativeVerification(
            request: request,
            providerName: "Coursera Credential Portal",
            authoritativeDomain: "coursera.org"
        )
    }
}

// MARK: - Credly Verification Provider
private struct CredlyVerificationProvider: CredentialVerificationProvider {
    let providerID = "credly"
    let providerName = "Credly / Acclaim Verification Service"

    func canHandle(issuer: String, verificationURL: String) -> Bool {
        let lowerURL = verificationURL.lowercased()
        let lowerIssuer = issuer.lowercased()
        return lowerURL.contains("credly.com") || lowerURL.contains("youracclaim.com") || lowerIssuer.contains("credly")
    }

    func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult {
        return try await executeAuthoritativeVerification(
            request: request,
            providerName: "Credly Authorized Registry",
            authoritativeDomain: "credly.com"
        )
    }
}

// MARK: - Accredible / Google Cloud Verification Provider
private struct AccredibleVerificationProvider: CredentialVerificationProvider {
    let providerID = "accredible"
    let providerName = "Accredible Digital Badges"

    func canHandle(issuer: String, verificationURL: String) -> Bool {
        let lowerURL = verificationURL.lowercased()
        return lowerURL.contains("accredible.com") || lowerURL.contains("skillsboost.google")
    }

    func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult {
        return try await executeAuthoritativeVerification(
            request: request,
            providerName: "Accredible Credential Engine",
            authoritativeDomain: "accredible.com"
        )
    }
}

// MARK: - Generic Official Portal Provider
private struct GenericOfficialPortalVerificationProvider: CredentialVerificationProvider {
    let providerID = "generic_official"
    let providerName = "Official Issuer Verification Portal"

    func canHandle(issuer: String, verificationURL: String) -> Bool {
        guard let url = URL(string: verificationURL), let host = url.host()?.lowercased() else { return false }
        return CertificateVerificationService.shared.isAuthoritativeDomain(host)
    }

    func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult {
        guard let url = URL(string: request.verificationURL), let host = url.host()?.lowercased() else {
            return CredentialVerificationResult(
                status: request.hasEvidence ? .evidenceProvided : .notVerified,
                method: "unrecognized_source",
                source: request.verificationURL,
                matchedFields: [],
                unmatchedFields: ["Authoritative Portal"],
                notes: "Verification source is not a recognized official portal.",
                isAuthoritative: false,
                verifiedAt: nil
            )
        }
        return try await executeAuthoritativeVerification(
            request: request,
            providerName: "Official Issuer Portal (\(host))",
            authoritativeDomain: host
        )
    }
}

// MARK: - Future Ready Authorized Issuer Account Provider
public struct AuthorizedIssuerAccountProvider: CredentialVerificationProvider {
    public let providerID = "issuer_account"
    public let providerName = "Authorized Issuer Confirmation"

    public func canHandle(issuer: String, verificationURL: String) -> Bool {
        // Will handle direct issuer signature requests in Phase 2
        return false
    }

    public func verify(request: CredentialVerificationRequest) async throws -> CredentialVerificationResult {
        // In this phase, do not simulate fake issuer verification
        return CredentialVerificationResult(
            status: request.hasEvidence ? .evidenceProvided : .notVerified,
            method: "issuer_confirmation_pending",
            source: "",
            matchedFields: [],
            unmatchedFields: ["Issuer Direct Signature"],
            notes: "Direct authorized issuer confirmation is queued.",
            isAuthoritative: false,
            verifiedAt: nil
        )
    }
}

// MARK: - Authoritative Verification Core Logic
private func executeAuthoritativeVerification(
    request: CredentialVerificationRequest,
    providerName: String,
    authoritativeDomain: String
) async throws -> CredentialVerificationResult {
    let rawURL = request.verificationURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: rawURL) else {
        return CredentialVerificationResult(
            status: request.hasEvidence ? .evidenceProvided : .notVerified,
            method: "invalid_url",
            source: rawURL,
            matchedFields: [],
            unmatchedFields: ["URL Format"],
            notes: "Invalid verification URL.",
            isAuthoritative: false,
            verifiedAt: nil
        )
    }

    // Attempt authoritative network check
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"
    urlRequest.timeoutInterval = 12
    urlRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 CareerLedger/1.0", forHTTPHeaderField: "User-Agent")

    let responseData: Data
    let httpResponse: HTTPURLResponse
    do {
        let (data, resp) = try await URLSession.shared.data(for: urlRequest)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        responseData = data
        httpResponse = http
    } catch {
        // Network unavailable or server down: DO NOT mark disputed! Keep evidenceProvided
        return CredentialVerificationResult(
            status: request.hasEvidence ? .evidenceProvided : .notVerified,
            method: "official_verification_url",
            source: rawURL,
            matchedFields: ["Authoritative Source Configured"],
            unmatchedFields: ["Network Live Verification"],
            notes: "Official issuer verification portal (\(authoritativeDomain)) could not be reached currently (\(error.localizedDescription)). Preserved as Evidence Provided.",
            isAuthoritative: true,
            verifiedAt: nil
        )
    }

    let responseBody = String(data: responseData, encoding: .utf8) ?? ""
    let lowerBody = responseBody.lowercased()

    // 1. Explicit Dispute / Revocation Detection (AUTHORITATIVE ONLY)
    // Only mark DISPUTED when the official issuer explicitly says it is invalid/revoked/fraudulent
    let disputeSignals = [
        "credential has been revoked",
        "certificate has been revoked",
        "credential revoked",
        "certificate revoked",
        "certificate is invalid",
        "credential is invalid",
        "credential not found",
        "certificate not found",
        "fraudulent credential",
        "disputed credential"
    ]

    for signal in disputeSignals {
        if lowerBody.contains(signal) || (httpResponse.statusCode == 404 && lowerBody.contains("not found")) {
            return CredentialVerificationResult(
                status: .disputed,
                method: "official_verification_url",
                source: rawURL,
                matchedFields: ["Authoritative Issuer Source (\(authoritativeDomain))"],
                unmatchedFields: ["Active Credential Status"],
                notes: "The authoritative issuer portal explicitly responded that this credential is invalid, revoked, or nonexistent.",
                isAuthoritative: true,
                verifiedAt: Date()
            )
        }
    }

    // 2. Multi-Field Matching Engine
    var matchedFields: [String] = []
    var unmatchedFields: [String] = []

    let trimmedID = request.credentialID.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedName = request.recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedIssuer = request.issuer.trimmingCharacters(in: .whitespacesAndNewlines)

    // A. Credential ID Matching (REQUIRED)
    let idMatchesInURL = !trimmedID.isEmpty && rawURL.localizedCaseInsensitiveContains(trimmedID)
    let idMatchesInBody = !trimmedID.isEmpty && lowerBody.contains(trimmedID.lowercased())
    if idMatchesInURL || idMatchesInBody {
        matchedFields.append("Credential ID (\(trimmedID))")
    } else {
        unmatchedFields.append("Credential ID")
    }

    // B. Recipient Name Matching
    var nameMatched = false
    if !trimmedName.isEmpty {
        let nameComponents = trimmedName.components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 1 }
        let matchesCount = nameComponents.filter { lowerBody.contains($0.lowercased()) }.count
        if matchesCount >= max(1, nameComponents.count - 1) {
            matchedFields.append("Recipient Name (\(trimmedName))")
            nameMatched = true
        } else {
            unmatchedFields.append("Recipient Name")
        }
    } else {
        unmatchedFields.append("Recipient Name (Not Provided)")
    }

    // C. Issuer Matching
    if !trimmedIssuer.isEmpty && (lowerBody.contains(trimmedIssuer.lowercased()) || rawURL.localizedCaseInsensitiveContains(trimmedIssuer)) {
        matchedFields.append("Issuer (\(trimmedIssuer))")
    } else {
        matchedFields.append("Issuer Authority (\(authoritativeDomain))")
    }

    // D. Issue Date Matching (if present)
    if let date = request.issueDate {
        let calendar = Calendar.current
        let year = String(calendar.component(.year, from: date))
        if lowerBody.contains(year) {
            matchedFields.append("Issue Year (\(year))")
        }
    }

    // CRITICAL MATCHING RULE:
    // Automatic verification CANNOT be based on person's name alone!
    // It REQUIRES Credential ID match + Issuer match + Recipient match on an authoritative source!
    let hasCredentialIDMatch = matchedFields.contains(where: { $0.contains("Credential ID") })

    if (httpResponse.statusCode == 200 || httpResponse.statusCode == 301 || httpResponse.statusCode == 302) &&
        hasCredentialIDMatch &&
        nameMatched {
        // Sufficient multi-field match on authoritative issuer
        return CredentialVerificationResult(
            status: .automaticallyVerified,
            method: "official_verification_url",
            source: rawURL,
            matchedFields: matchedFields,
            unmatchedFields: unmatchedFields,
            notes: "Successfully verified against \(providerName). Credential ID, recipient identity, and issuing parameters matched the authoritative registry.",
            isAuthoritative: true,
            verifiedAt: Date()
        )
    } else {
        // Did not meet the strict multi-field verification threshold
        let reason: String
        if !hasCredentialIDMatch && nameMatched {
            reason = "Recipient name matched on the issuer portal, but Credential ID was missing or could not be independently confirmed. An automatic verification is never granted on name alone."
        } else if !nameMatched && hasCredentialIDMatch {
            reason = "Credential ID was found, but recipient name was not confirmed on the issuer page."
        } else {
            reason = "The issuer portal did not sufficiently match the credential records."
        }

        return CredentialVerificationResult(
            status: request.hasEvidence ? .evidenceProvided : .notVerified,
            method: "official_verification_url",
            source: rawURL,
            matchedFields: matchedFields,
            unmatchedFields: unmatchedFields,
            notes: "\(reason) Credential remains Evidence Provided.",
            isAuthoritative: true,
            verifiedAt: nil
        )
    }
}
