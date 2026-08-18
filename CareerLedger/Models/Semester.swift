import Foundation

struct Subject: Identifiable {
    let id = UUID()
    var name: String
    var grade: String
}

struct Semester: Identifiable {
    let id = UUID()
    var number: Int
    var sgpa: Double
    var subjects: [Subject]
}

let sampleSemesters = [
    Semester(
        number: 1,
        sgpa: 8.2,
        subjects: [
            Subject(name: "Programming", grade: "A"),
            Subject(name: "Mathematics", grade: "A+"),
            Subject(name: "Physics", grade: "B+")
        ]
    ),
    Semester(
        number: 2,
        sgpa: 8.6,
        subjects: [
            Subject(name: "Data Structures", grade: "A+"),
            Subject(name: "Database Systems", grade: "A"),
            Subject(name: "English", grade: "A")
        ]
    )
]
