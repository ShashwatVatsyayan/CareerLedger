import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit

enum PDFService {
    static func generateCareerLedgerPDF(
        student: Student?,
        semesters: [Semester],
        projects: [Project],
        achievements: [Achievement],
        certificates: [Certificate]
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let fileName = "CareerLedger-\(student?.name.replacingOccurrences(of: " ", with: "-") ?? "Student").pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let cgpa = PortfolioMetrics.cgpa(from: semesters)

        try renderer.writePDF(to: outputURL) { context in
            var y: CGFloat = 42

            func newPageIfNeeded(_ requiredHeight: CGFloat) {
                if y + requiredHeight > pageRect.height - 54 {
                    context.beginPage()
                    y = 42
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .label, x: CGFloat = 44, width: CGFloat = 524, link: URL? = nil) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 3
                var attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: link != nil ? UIColor.systemBlue : color,
                    .paragraphStyle: paragraph
                ]
                if let link {
                    attributes[.link] = link
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }

                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                let textRect = CGRect(x: x, y: y, width: width, height: ceil(rect.height))
                NSString(string: text).draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                y += ceil(rect.height) + 6
            }

            func drawSection(_ title: String) {
                newPageIfNeeded(70)
                y += 12
                UIColor.systemBlue.setFill()
                UIBezierPath(roundedRect: CGRect(x: 44, y: y, width: 524, height: 28), cornerRadius: 6).fill()
                drawText(title.uppercased(), font: .systemFont(ofSize: 12, weight: .bold), color: .white, x: 54, width: 504)
                y += 4
            }

            func drawItem(title: String, subtitle: String? = nil, details: [(label: String, value: String, url: URL?)] = []) {
                newPageIfNeeded(85)
                UIColor.separator.withAlphaComponent(0.3).setFill()
                UIBezierPath(rect: CGRect(x: 44, y: y, width: 524, height: 0.8)).fill()
                y += 10
                drawText(title, font: .systemFont(ofSize: 14, weight: .bold))
                if let subtitle, !subtitle.isEmpty {
                    drawText(subtitle, font: .systemFont(ofSize: 11), color: .secondaryLabel)
                }
                for detail in details where !detail.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let url = detail.url {
                        drawText("\(detail.label): \(detail.value)", font: .systemFont(ofSize: 10, weight: .medium), color: .systemBlue, link: url)
                    } else {
                        drawText("\(detail.label): \(detail.value)", font: .systemFont(ofSize: 10), color: .secondaryLabel)
                    }
                }
                y += 2
            }

            context.beginPage()

            // Header
            drawText("CAREER LEDGER", font: .systemFont(ofSize: 26, weight: .heavy), color: .systemBlue)
            drawText(student?.name ?? "Shashwat Vatsyayan", font: .systemFont(ofSize: 20, weight: .bold))
            drawText("\(student?.course ?? "B.E. Computer Science") • \(student?.university ?? "Chandigarh University")", font: .systemFont(ofSize: 12), color: .secondaryLabel)

            if let bio = student?.bio, !bio.isEmpty {
                drawText("“\(bio)”", font: .italicSystemFont(ofSize: 11), color: .darkGray)
            }

            // QR Code
            if let qrImage = qrCodeImage(from: student?.portfolioURL.isEmpty == false ? student!.portfolioURL : "https://careerledger.app/student") {
                qrImage.draw(in: CGRect(x: 482, y: 42, width: 80, height: 80))
                let oldY = y
                y = 126
                drawText("Scan Verified Ledger", font: .systemFont(ofSize: 8, weight: .medium), color: .secondaryLabel, x: 462, width: 110)
                y = max(oldY, y)
            }

            // Professional Profiles & Contacts
            drawSection("Verified Profiles & Contact")
            var contacts: [(label: String, value: String, url: URL?)] = []
            if let email = student?.email, !email.isEmpty {
                contacts.append((label: "Email", value: email, url: URL(string: "mailto:\(email)")))
            }
            if let github = student?.githubURL, !github.isEmpty {
                contacts.append((label: "GitHub", value: github, url: validURL(github)))
            }
            if let linkedin = student?.linkedinURL, !linkedin.isEmpty {
                contacts.append((label: "LinkedIn", value: linkedin, url: validURL(linkedin)))
            }
            if let portfolio = student?.portfolioURL, !portfolio.isEmpty {
                contacts.append((label: "Portfolio", value: portfolio, url: validURL(portfolio)))
            }
            drawItem(title: "Contact & Online Presence", details: contacts)

            // Education
            drawSection("Education & Academic Ledger")
            let eduDetails = semesters.sorted { $0.semesterNumber < $1.semesterNumber }.map {
                (label: "Semester \($0.semesterNumber)", value: "SGPA \(String(format: "%.1f", $0.sgpa)) • \($0.subjects.count) subjects (\($0.subjects.map { "\($0.name): \($0.grade)" }.joined(separator: ", ")))", url: nil as URL?)
            }
            drawItem(title: cgpa > 0 ? "Overall CGPA \(String(format: "%.2f", cgpa))" : "Academic Records", details: eduDetails)

            // Projects
            drawSection("Projects & Artifacts")
            if projects.isEmpty {
                drawItem(title: "No projects recorded")
            } else {
                for project in projects.sorted(by: { $0.date > $1.date }) {
                    var projectDetails: [(label: String, value: String, url: URL?)] = [
                        (label: "Tech Stack", value: project.technologies, url: nil),
                        (label: "Verification", value: project.verificationStatus.displayName, url: nil)
                    ]
                    if !project.githubURL.isEmpty {
                        projectDetails.append((label: "Repository", value: project.githubURL, url: validURL(project.githubURL)))
                    }
                    if !project.demoURL.isEmpty {
                        projectDetails.append((label: "Live Demo", value: project.demoURL, url: validURL(project.demoURL)))
                    }
                    drawItem(title: project.name, subtitle: project.projectDescription, details: projectDetails)
                }
            }

            // Achievements
            drawSection("Achievements & Honors")
            if achievements.isEmpty {
                drawItem(title: "No achievements recorded")
            } else {
                for achievement in achievements.sorted(by: { $0.date > $1.date }) {
                    var achDetails: [(label: String, value: String, url: URL?)] = [
                        (label: "Category", value: achievement.category, url: nil),
                        (label: "Verification", value: achievement.verificationStatus.displayName, url: nil)
                    ]
                    if !achievement.credentialID.isEmpty {
                        achDetails.append((label: "Credential ID", value: achievement.credentialID, url: nil))
                    }
                    if !achievement.evidenceURL.isEmpty {
                        achDetails.append((label: "Evidence Link", value: achievement.evidenceURL, url: validURL(achievement.evidenceURL)))
                    }
                    drawItem(title: achievement.title, subtitle: "\(achievement.organization) • \(dateFormatter.string(from: achievement.date))", details: achDetails)
                }
            }

            // Certificates
            drawSection("Certificates & Credentials")
            if certificates.isEmpty {
                drawItem(title: "No certificates recorded")
            } else {
                for certificate in certificates.sorted(by: { $0.issueDate > $1.issueDate }) {
                    var certDetails: [(label: String, value: String, url: URL?)] = [
                        (label: "Verification Status", value: certificate.verificationStatus.displayName, url: nil)
                    ]
                    if !certificate.credentialID.isEmpty {
                        certDetails.append((label: "Credential ID", value: certificate.credentialID, url: nil))
                    }
                    if !certificate.verificationURL.isEmpty {
                        certDetails.append((label: "Validation URL", value: certificate.verificationURL, url: validURL(certificate.verificationURL)))
                    }
                    drawItem(title: certificate.title, subtitle: "Issued by \(certificate.issuer) • \(dateFormatter.string(from: certificate.issueDate))", details: certDetails)
                }
            }

            // Skills
            drawSection("Core Competencies")
            drawItem(title: (student?.skills ?? []).joined(separator: " • "), subtitle: "Verified technical capabilities backed by SwiftData records.")
        }

        return outputURL
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static func qrCodeImage(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transform = CGAffineTransform(scaleX: 8, y: 8)
        let scaledImage = outputImage.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private static func validURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#elseif canImport(AppKit)
import AppKit

enum PDFService {
    static func generateCareerLedgerPDF(
        student: Student?,
        semesters: [Semester],
        projects: [Project],
        achievements: [Achievement],
        certificates: [Certificate]
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let fileName = "CareerLedger-\(student?.name.replacingOccurrences(of: " ", with: "-") ?? "Student").pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let cgpa = PortfolioMetrics.cgpa(from: semesters)

        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(url: outputURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        context.beginPage(mediaBox: &mediaBox)
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: true)
        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = graphicsContext

        var y: CGFloat = 42

        func drawText(_ text: String, font: NSFont, color: NSColor = .labelColor, x: CGFloat = 44, width: CGFloat = 524) {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 3
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
            let rect = NSString(string: text).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes
            )
            NSString(string: text).draw(with: CGRect(x: x, y: y, width: width, height: ceil(rect.height)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
            y += ceil(rect.height) + 7
        }

        func drawSection(_ title: String) {
            y += 12
            NSColor.systemBlue.setFill()
            NSBezierPath(roundedRect: CGRect(x: 44, y: y, width: 524, height: 28), xRadius: 6, yRadius: 6).fill()
            drawText(title.uppercased(), font: .boldSystemFont(ofSize: 12), color: .white, x: 54, width: 504)
            y += 4
        }

        func drawItem(title: String, subtitle: String? = nil, details: [String] = []) {
            NSColor.separatorColor.withAlphaComponent(0.3).setFill()
            NSBezierPath(rect: CGRect(x: 44, y: y, width: 524, height: 0.8)).fill()
            y += 10
            drawText(title, font: .boldSystemFont(ofSize: 14))
            if let subtitle, !subtitle.isEmpty {
                drawText(subtitle, font: .systemFont(ofSize: 11), color: .secondaryLabelColor)
            }
            for detail in details where !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawText(detail, font: .systemFont(ofSize: 10), color: .secondaryLabelColor)
            }
            y += 2
        }

        drawText("CAREER LEDGER", font: .boldSystemFont(ofSize: 26), color: .systemBlue)
        drawText(student?.name ?? "Shashwat Vatsyayan", font: .boldSystemFont(ofSize: 20))
        drawText("\(student?.course ?? "B.E. Computer Science") • \(student?.university ?? "Chandigarh University")", font: .systemFont(ofSize: 12), color: .secondaryLabelColor)

        drawSection("Education")
        let eduLines = semesters.sorted { $0.semesterNumber < $1.semesterNumber }.map {
            "Semester \($0.semesterNumber): SGPA \(String(format: "%.1f", $0.sgpa)) (\($0.subjects.count) subjects)"
        }
        drawItem(title: cgpa > 0 ? "Overall CGPA \(String(format: "%.2f", cgpa))" : "Academic Records", details: eduLines)

        drawSection("Projects")
        for project in projects.sorted(by: { $0.date > $1.date }) {
            drawItem(title: project.name, subtitle: project.projectDescription, details: [
                "Technologies: \(project.technologies)",
                "GitHub: \(project.githubURL)",
                "Demo: \(project.demoURL)"
            ])
        }

        drawSection("Achievements")
        for achievement in achievements.sorted(by: { $0.date > $1.date }) {
            drawItem(title: achievement.title, subtitle: "\(achievement.organization) • \(achievement.category)", details: [
                achievement.achievementDescription,
                "Verification: \(achievement.verificationStatus.displayName)",
                "Evidence: \(achievement.evidenceURL)"
            ])
        }

        drawSection("Certificates")
        for certificate in certificates.sorted(by: { $0.issueDate > $1.issueDate }) {
            drawItem(title: certificate.title, subtitle: "Issued by \(certificate.issuer)", details: [
                "Credential ID: \(certificate.credentialID)",
                "Verification: \(certificate.verificationStatus.displayName)",
                "Validation URL: \(certificate.verificationURL)"
            ])
        }

        NSGraphicsContext.current = previousContext
        context.endPage()
        context.closePDF()

        return outputURL
    }
}
#endif
