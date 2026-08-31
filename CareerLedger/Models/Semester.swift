import Foundation
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var name: String
    var grade: String
    var semester: Semester?

    init(id: UUID = UUID(), name: String, grade: String) {
        self.id = id
        self.name = name
        self.grade = grade
    }
}

@Model
final class Semester {
    @Attribute(.unique) var id: UUID
    var semesterNumber: Int
    var sgpa: Double
    @Relationship(deleteRule: .cascade, inverse: \Subject.semester) var subjects: [Subject]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        semesterNumber: Int,
        sgpa: Double,
        subjects: [Subject] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.semesterNumber = semesterNumber
        self.sgpa = sgpa
        self.subjects = subjects
        self.createdAt = createdAt
    }
}
