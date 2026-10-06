import Foundation
import UIKit
import PDFKit
@preconcurrency import Vision

public final class CertificateEvidenceExtractor: @unchecked Sendable {
    public static let shared = CertificateEvidenceExtractor()

    private init() {}

    /// Extracts structured details from uploaded evidence (PDF or Image)
    public func extractDetails(from data: Data, filename: String) async -> ExtractedCertificateDetails {
        let ext = (filename as NSString).pathExtension.lowercased()

        if ext == "pdf" || data.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return await extractFromPDF(data: data)
        } else {
            return await extractFromImage(data: data)
        }
    }

    // MARK: - PDF Extraction
    private func extractFromPDF(data: Data) async -> ExtractedCertificateDetails {
        guard let doc = PDFDocument(data: data) else {
            return ExtractedCertificateDetails(rawText: "", confidence: 0.0)
        }

        var fullText = ""
        var qrPayload: String? = nil

        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i) {
                if let pageString = page.string {
                    fullText += pageString + "\n"
                }

                // If page 1, render to image to detect any embedded QR code
                if i == 0, qrPayload == nil {
                    let pageRect = page.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let image = renderer.image { ctx in
                        UIColor.white.set()
                        ctx.fill(pageRect)
                        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                        page.draw(with: .mediaBox, to: ctx.cgContext)
                    }
                    if let cgImage = image.cgImage {
                        qrPayload = detectQRCode(in: cgImage)
                    }
                }
            }
        }

        var details = parseCertificateText(fullText)
        if let qr = qrPayload, !qr.isEmpty {
            details.qrCodePayload = qr
            if details.verificationURL.isEmpty && qr.hasPrefix("http") {
                details.verificationURL = qr
            }
        }
        return details
    }

    // MARK: - Image Extraction
    private func extractFromImage(data: Data) async -> ExtractedCertificateDetails {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return ExtractedCertificateDetails(rawText: "", confidence: 0.0)
        }

        let qrPayload = detectQRCode(in: cgImage)
        let ocrText = await performOCR(cgImage: cgImage)

        var details = parseCertificateText(ocrText)
        if let qr = qrPayload, !qr.isEmpty {
            details.qrCodePayload = qr
            if details.verificationURL.isEmpty && qr.hasPrefix("http") {
                details.verificationURL = qr
            }
        }
        return details
    }

    // MARK: - Vision OCR
    private func performOCR(cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }

    // MARK: - Vision QR Code Detection
    private func detectQRCode(in cgImage: CGImage) -> String? {
        var detectedPayload: String?
        let request = VNDetectBarcodesRequest { request, _ in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            for barcode in observations where barcode.symbology == .qr {
                if let payload = barcode.payloadStringValue, !payload.isEmpty {
                    detectedPayload = payload
                    break
                }
            }
        }
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return detectedPayload
    }

    // MARK: - Text Parsing Heuristics
    public func parseCertificateText(_ rawText: String) -> ExtractedCertificateDetails {
        var details = ExtractedCertificateDetails(rawText: rawText)
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 1. Verification URL detection
        if let url = extractVerificationURL(from: rawText) {
            details.verificationURL = url
        }

        // 2. Issuer detection
        details.issuer = detectIssuer(from: rawText, lines: lines)

        // 3. Credential ID detection
        details.credentialID = detectCredentialID(from: rawText, lines: lines)

        // 4. Recipient Name detection
        details.recipientName = detectRecipientName(from: rawText, lines: lines)

        // 5. Title detection
        details.title = detectTitle(from: rawText, lines: lines, issuer: details.issuer)

        // 6. Dates detection
        let dates = detectDates(from: rawText)
        details.issueDate = dates.issueDate
        details.expiryDate = dates.expiryDate

        // Calculate confidence score (0.0 to 1.0)
        var score = 0.0
        if !details.title.isEmpty { score += 0.25 }
        if !details.issuer.isEmpty { score += 0.25 }
        if !details.credentialID.isEmpty { score += 0.25 }
        if !details.verificationURL.isEmpty { score += 0.15 }
        if details.issueDate != nil { score += 0.10 }
        details.confidence = score

        return details
    }

    private func extractVerificationURL(from text: String) -> String? {
        let pattern = #"(https?://[a-zA-Z0-9\-\.]+(?:\.[a-zA-Z]{2,})[^\s<>"]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        var bestURL: String? = nil
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let candidate = String(text[range])
            let lower = candidate.lowercased()
            // Prefer URLs with verify / credentials / badges / certificates
            if lower.contains("verify") || lower.contains("credential") || lower.contains("badge") || lower.contains("certificate") || lower.contains("coursera") || lower.contains("credly") || lower.contains("accredible") {
                return candidate
            }
            if bestURL == nil {
                bestURL = candidate
            }
        }
        return bestURL
    }

    private func detectIssuer(from text: String, lines: [String]) -> String {
        let issuers = [
            "Google Cloud", "Amazon Web Services", "AWS", "Microsoft", "Coursera",
            "Credly", "Accredible", "Chandigarh University", "Stanford University",
            "Harvard University", "Meta", "IBM", "Oracle", "Cisco", "CompTIA",
            "Udacity", "edX", "DeepLearning.AI", "Duke University", "MIT", "NPTEL",
            "FreeCodeCamp", "HackerRank", "LeetCode", "Databricks", "Kubernetes"
        ]

        for issuer in issuers {
            if text.localizedCaseInsensitiveContains(issuer) {
                return issuer
            }
        }

        // Look for lines containing "University", "College", "Institute", "Academy"
        for line in lines {
            let lower = line.lowercased()
            if (lower.contains("university") || lower.contains("institute") || lower.contains("academy")) && line.count < 60 {
                return line
            }
        }

        return ""
    }

    private func detectCredentialID(from text: String, lines: [String]) -> String {
        // Regex pattern: Credential ID / Certificate ID / License #
        let pattern = #"(?i)(?:credential\s*id|certificate\s*id|license\s*(?:id|number|no|#)|badge\s*id|cert\s*id|id)\s*[:#\-]?\s*([a-zA-Z0-9\-_.]{6,36})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Fallback: look for lines starting with ID
        for line in lines {
            let lower = line.lowercased()
            if lower.hasPrefix("id:") || lower.hasPrefix("certificate id:") || lower.hasPrefix("credential id:") {
                let parts = line.components(separatedBy: ":")
                if parts.count > 1 {
                    let id = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if id.count >= 4 { return id }
                }
            }
        }
        return ""
    }

    private func detectRecipientName(from text: String, lines: [String]) -> String {
        let pattern = #"(?i)(?:this is to certify that|certifies that|awarded to|presented to|conferred upon|certify that)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){1,3})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // If authenticated user name matches any line
        let userFullName = SupabaseManager.shared.currentUserFullName
        if !userFullName.isEmpty && text.localizedCaseInsensitiveContains(userFullName) {
            return userFullName
        }

        return ""
    }

    private func detectTitle(from text: String, lines: [String], issuer: String) -> String {
        // Look for line following "successfully completed" or "for completing"
        for i in 0..<lines.count {
            let lower = lines[i].lowercased()
            if lower.contains("successfully completed") || lower.contains("has completed") || lower.contains("completion of") {
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1]
                    if nextLine.count > 3 && nextLine.count < 80 && !nextLine.localizedCaseInsensitiveContains(issuer) {
                        return nextLine
                    }
                }
            }
        }

        // Look for title keywords
        let titleKeywords = [
            "Specialization", "Associate Cloud Engineer", "Solutions Architect",
            "Professional Data Engineer", "Machine Learning", "Data Science",
            "Full Stack Web Development", "iOS Development", "SwiftUI Specialist",
            "Cybersecurity Analyst", "Cloud Practitioner"
        ]
        for kw in titleKeywords {
            if let line = lines.first(where: { $0.localizedCaseInsensitiveContains(kw) }) {
                return line
            }
        }

        // Default to first meaningful non-issuer line
        for line in lines {
            if line.count > 5 && line.count < 65 && line != issuer && !line.lowercased().contains("certificate") {
                return line
            }
        }

        return "Certificate of Achievement"
    }

    private func detectDates(from text: String) -> (issueDate: Date?, expiryDate: Date?) {
        let pattern = #"\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2},?\s+\d{4}\b|\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (nil, nil)
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let formatters: [DateFormatter] = [
            {
                let df = DateFormatter()
                df.dateFormat = "MMMM d, yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "MMM d, yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "MM/dd/yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "dd/MM/yyyy"
                return df
            }()
        ]

        var parsedDates: [Date] = []
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let str = String(text[range])
            for df in formatters {
                if let d = df.date(from: str) {
                    parsedDates.append(d)
                    break
                }
            }
        }

        if parsedDates.isEmpty {
            return (nil, nil)
        } else if parsedDates.count == 1 {
            return (parsedDates[0], nil)
        } else {
            parsedDates.sort()
            return (parsedDates[0], parsedDates.last)
        }
    }
}
