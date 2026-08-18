import Foundation
import Combine

final class PortfolioStore: ObservableObject {
    @Published var student = sampleStudent
    @Published var semesters = sampleSemesters
    @Published var achievements = sampleAchievements
    @Published var projects = sampleProjects
    @Published var certificates = sampleCertificates

    var cgpa: Double {
        guard !semesters.isEmpty else {
            return 0
        }

        let total = semesters.reduce(0) { $0 + $1.sgpa }
        return total / Double(semesters.count)
    }
}

