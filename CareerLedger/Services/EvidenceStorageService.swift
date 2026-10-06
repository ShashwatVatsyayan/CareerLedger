import Foundation
import CryptoKit
import Supabase

public final class EvidenceStorageService: @unchecked Sendable {
    public static let shared = EvidenceStorageService()

    private let fileManager = FileManager.default
    private let evidenceDirectory: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        evidenceDirectory = docs.appendingPathComponent("CertificateEvidence", isDirectory: true)
        if !fileManager.fileExists(atPath: evidenceDirectory.path) {
            try? fileManager.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)
        }
    }

    /// Stores evidence document locally and optionally in Supabase Storage with SHA-256 deduplication.
    public func storeEvidence(
        data: Data,
        originalFilename: String,
        mimeType: String,
        certificateID: UUID
    ) async -> String {
        // 1. Calculate SHA-256 checksum to prevent duplicate storage
        let digest = SHA256.hash(data: data)
        let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()
        let fileExtension = (originalFilename as NSString).pathExtension.lowercased()
        let safeExtension = fileExtension.isEmpty ? "pdf" : fileExtension
        let storageFilename = "\(hashString).\(safeExtension)"
        let localFileURL = evidenceDirectory.appendingPathComponent(storageFilename)

        // 2. Save locally if not already present
        if !fileManager.fileExists(atPath: localFileURL.path) {
            try? data.write(to: localFileURL, options: .atomic)
        }

        // 3. Attempt to upload to Supabase Storage if authenticated
        if let session = SupabaseManager.shared.currentSession {
            let userUUID = session.user.id.uuidString
            let remotePath = "\(userUUID)/\(storageFilename)"
            do {
                _ = try await SupabaseManager.shared.client.storage
                    .from("certificate-evidence")
                    .upload(
                        path: remotePath,
                        file: data,
                        options: FileOptions(contentType: mimeType, upsert: true)
                    )
                // Retrieve public or signed URL
                if let publicURL = try? SupabaseManager.shared.client.storage
                    .from("certificate-evidence")
                    .getPublicURL(path: remotePath) {
                    return publicURL.absoluteString
                }
            } catch {
                // If Supabase Storage bucket is not ready or user is offline, gracefully fallback to local file URL
                #if DEBUG
                print("[EvidenceStorageService] Remote storage upload fallback: \(error.localizedDescription)")
                #endif
            }
        }

        // Fallback to local storage URL reference
        return localFileURL.absoluteString
    }

    /// Retrieves data for a given evidence URL (handles both local file and remote URLs)
    public func loadEvidenceData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        if url.isFileURL {
            return try? Data(contentsOf: url)
        }

        // If it's a remote URL, fetch data
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        return data
    }
}
