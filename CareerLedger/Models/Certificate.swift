import Foundation

struct Certificate: Identifiable {
    let id = UUID()
    var title: String
    var organization: String
    var date: Date
    var credentialID: String
}

let sampleCertificates = [
    Certificate(
        title: "Swift Fundamentals",
        organization: "Example Academy",
        date: Date(),
        credentialID: "CERT-001"
    )
]
