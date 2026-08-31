import Foundation

enum PortfolioMetrics {
    static func cgpa(from semesters: [Semester]) -> Double {
        guard !semesters.isEmpty else {
            return 0
        }

        let total = semesters.reduce(0) { $0 + $1.sgpa }
        return total / Double(semesters.count)
    }
}
