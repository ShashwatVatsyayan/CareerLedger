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

            func drawText(_ text: String, font: UIFont, color: UIColor = .label, x: CGFloat = 44, width: CGFloat = 524) {
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
                    attributes: attributes,
                    context: nil
                )
                NSString(string: text).draw(with: CGRect(x: x, y: y, width: width, height: ceil(rect.height)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                y += ceil(rect.height) + 7
            }

            func drawSection(_ title: String) {
                newPageIfNeeded(70)
                y += 12
                UIColor.systemBlue.setFill()
                UIBezierPath(roundedRect: CGRect(x: 44, y: y, width: 524, height: 30), cornerRadius: 8).fill()
                drawText(title.uppercased(), font: .systemFont(ofSize: 13, weight: .bold), color: .white, x: 56, width: 500)
                y += 4
            }

            func drawItem(title: String, lines: [String]) {
                newPageIfNeeded(92)
                UIColor.secondarySystemBackground.setFill()
                UIBezierPath(roundedRect: CGRect(x: 44, y: y, width: 524, height: 1), cornerRadius: 0).fill()
                y += 12
                drawText(title, font: .systemFont(ofSize: 15, weight: .semibold))
                for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    drawText(line, font: .systemFont(ofSize: 11), color: .secondaryLabel)
                }
                y += 3
            }

            context.beginPage()

            drawText("CAREER LEDGER", font: .systemFont(ofSize: 28, weight: .heavy), color: .systemBlue)
            drawText(student?.name ?? "Student", font: .systemFont(ofSize: 22, weight: .bold))
            drawText("\(student?.course ?? "Student") | \(student?.university ?? "University")", font: .systemFont(ofSize: 13), color: .secondaryLabel)

            if let qrImage = qrCodeImage(from: student?.portfolioURL ?? "https://careerledger.example.com/demo") {
                qrImage.draw(in: CGRect(x: 482, y: 42, width: 82, height: 82))
                let oldY = y
                y = 128
                drawText("Scan to view Career Ledger profile", font: .systemFont(ofSize: 8), color: .secondaryLabel, x: 456, width: 112)
                y = max(oldY, y)
            }

            drawSection("Education")
            drawItem(title: cgpa > 0 ? "CGPA \(String(format: "%.2f", cgpa))" : "No academic records yet", lines: semesters.sorted { $0.semesterNumber < $1.semesterNumber }.map {
                "Semester \($0.semesterNumber): SGPA \(String(format: "%.1f", $0.sgpa)) | \($0.subjects.count) subjects"
            })

            drawSection("Projects")
            if projects.isEmpty {
                drawItem(title: "No projects added", lines: [])
            } else {
                for project in projects.sorted(by: { $0.date > $1.date }) {
                    drawItem(title: project.name, lines: [
                        project.projectDescription,
                        "Technologies: \(project.technologies)",
                        "GitHub: \(project.githubURL)",
                        "Demo: \(project.demoURL)"
                    ])
                }
            }

            drawSection("Achievements")
            if achievements.isEmpty {
                drawItem(title: "No achievements added", lines: [])
            } else {
                for achievement in achievements.sorted(by: { $0.date > $1.date }) {
                    drawItem(title: achievement.title, lines: [
                        "\(achievement.organization) | \(dateFormatter.string(from: achievement.date))",
                        achievement.achievementDescription,
                        "Verification: \(achievement.verificationStatus.displayName)",
                        "Evidence: \(achievement.evidenceURL)"
                    ])
                }
            }

            drawSection("Certificates")
            if certificates.isEmpty {
                drawItem(title: "No certificates added", lines: [])
            } else {
                for certificate in certificates.sorted(by: { $0.issueDate > $1.issueDate }) {
                    drawItem(title: certificate.title, lines: [
                        "\(certificate.issuer) | \(dateFormatter.string(from: certificate.issueDate))",
                        "Credential ID: \(certificate.credentialID)",
                        "Verification: \(certificate.verificationStatus.displayName)",
                        "Verification URL: \(certificate.verificationURL)"
                    ])
                }
            }

            drawSection("Skills")
            drawItem(title: student?.skills.joined(separator: ", ") ?? "No skills added", lines: ["Evidence available through linked projects, certificates, and achievements."])

            drawSection("Professional Links")
            drawItem(title: "Links", lines: [
                "GitHub: \(student?.githubURL ?? "")",
                "LinkedIn: \(student?.linkedinURL ?? "")",
                "Career Ledger: \(student?.portfolioURL ?? "https://careerledger.example.com/demo")"
            ])

            drawSection("Career Ledger Verification")
            drawText("Expo MVP: local PDF generated from current SwiftData records. Online issuer verification is represented by status fields and can be connected to a backend later.", font: .systemFont(ofSize: 11), color: .secondaryLabel)
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
            NSBezierPath(roundedRect: CGRect(x: 44, y: y, width: 524, height: 30), xRadius: 8, yRadius: 8).fill()
            drawText(title.uppercased(), font: .boldSystemFont(ofSize: 13), color: .white, x: 56, width: 500)
            y += 4
        }

        func drawItem(title: String, lines: [String]) {
            NSColor.secondaryLabelColor.withAlphaComponent(0.2).setFill()
            NSBezierPath(rect: CGRect(x: 44, y: y, width: 524, height: 1)).fill()
            y += 12
            drawText(title, font: .boldSystemFont(ofSize: 15))
            for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawText(line, font: .systemFont(ofSize: 11), color: .secondaryLabelColor)
            }
            y += 3
        }

        drawText("CAREER LEDGER", font: .boldSystemFont(ofSize: 28), color: .systemBlue)
        drawText(student?.name ?? "Student", font: .boldSystemFont(ofSize: 22))
        drawText("\(student?.course ?? "Student") | \(student?.university ?? "University")", font: .systemFont(ofSize: 13), color: .secondaryLabelColor)

        drawSection("Education")
        drawItem(title: cgpa > 0 ? "CGPA \(String(format: "%.2f", cgpa))" : "No academic records yet", lines: semesters.sorted { $0.semesterNumber < $1.semesterNumber }.map {
            "Semester \($0.semesterNumber): SGPA \(String(format: "%.1f", $0.sgpa)) | \($0.subjects.count) subjects"
        })

        drawSection("Projects")
        for project in projects.sorted(by: { $0.date > $1.date }) {
            drawItem(title: project.name, lines: [
                project.projectDescription,
                "Technologies: \(project.technologies)",
                "GitHub: \(project.githubURL)",
                "Demo: \(project.demoURL)"
            ])
        }

        drawSection("Achievements")
        for achievement in achievements.sorted(by: { $0.date > $1.date }) {
            drawItem(title: achievement.title, lines: [
                "\(achievement.organization) | \(achievement.category)",
                achievement.achievementDescription,
                "Verification: \(achievement.verificationStatus.displayName)"
            ])
        }

        drawSection("Certificates")
        for certificate in certificates.sorted(by: { $0.issueDate > $1.issueDate }) {
            drawItem(title: certificate.title, lines: [
                "\(certificate.issuer) | Credential ID: \(certificate.credentialID)",
                "Verification: \(certificate.verificationStatus.displayName)"
            ])
        }

        NSGraphicsContext.current = previousContext
        context.endPage()
        context.closePDF()

        return outputURL
    }
}
#endif
