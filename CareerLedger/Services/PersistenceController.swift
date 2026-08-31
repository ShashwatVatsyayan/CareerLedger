import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        Student.self,
        Achievement.self,
        Project.self,
        Certificate.self,
        Semester.self,
        Subject.self
    ])

    static func seedIfNeeded(
        modelContext: ModelContext,
        students: [Student],
        achievements: [Achievement],
        projects: [Project],
        certificates: [Certificate],
        semesters: [Semester]
    ) {
        guard students.isEmpty,
              achievements.isEmpty,
              projects.isEmpty,
              certificates.isEmpty,
              semesters.isEmpty else {
            return
        }

        let student = Student(
            name: "Shashwat Vatsyayan",
            course: "B.E. Computer Science",
            university: "Chandigarh University",
            email: "student@example.com",
            bio: "Computer Science student building practical AI, iOS, and web products with a focus on verified career evidence.",
            githubURL: "https://github.com/",
            linkedinURL: "https://www.linkedin.com/",
            universityURL: "https://www.cuchd.in/",
            instagramURL: "https://www.instagram.com/",
            portfolioURL: "https://careerledger.example.com/shashwat-vatsyayan",
            skills: ["SwiftUI", "SwiftData", "Python", "Machine Learning", "Firebase", "Product Design"]
        )

        let demoAchievements = [
            Achievement(
                title: "Hackathon Winner",
                organization: "Chandigarh University",
                date: date(year: 2026, month: 2, day: 18),
                category: "Technical",
                description: "Won first place for a student productivity prototype built during a 24-hour campus hackathon.",
                credentialID: "HACK-2026-001",
                evidenceURL: "https://careerledger.example.com/evidence/hackathon",
                verificationStatus: .issuerVerified
            ),
            Achievement(
                title: "Coding Competition",
                organization: "Computer Science Club",
                date: date(year: 2025, month: 11, day: 8),
                category: "Technical",
                description: "Ranked in the top finalists in an algorithmic programming contest.",
                credentialID: "CODE-2025-12850",
                evidenceURL: "https://careerledger.example.com/evidence/coding",
                verificationStatus: .evidenceProvided
            ),
            Achievement(
                title: "Leadership Award",
                organization: "Student Innovation Cell",
                date: date(year: 2025, month: 9, day: 12),
                category: "Leadership",
                description: "Recognized for coordinating student project demos and mentoring junior teams.",
                verificationStatus: .selfReported
            )
        ]

        let demoProjects = [
            Project(
                name: "Aegis AI",
                description: "AI-assisted media authenticity tool for detecting manipulated or deepfake content.",
                technologies: "Python, Machine Learning, Flask",
                githubURL: "https://github.com/",
                demoURL: "https://careerledger.example.com/projects/aegis-ai",
                verificationStatus: .evidenceProvided,
                date: date(year: 2026, month: 3, day: 2)
            ),
            Project(
                name: "uniVerse",
                description: "Campus companion app concept for academic planning, events, and verified student profiles.",
                technologies: "SwiftUI, SwiftData, CloudKit",
                githubURL: "https://github.com/",
                demoURL: "https://careerledger.example.com/projects/universe",
                verificationStatus: .sourceVerified,
                date: date(year: 2026, month: 1, day: 16)
            )
        ]

        let demoCertificates = [
            Certificate(
                title: "Python for Data Science",
                issuer: "Example Academy",
                issueDate: date(year: 2025, month: 10, day: 4),
                credentialID: "PY-DS-2025-12850",
                verificationURL: "https://careerledger.example.com/certificates/python-data-science",
                verificationStatus: .issuerVerified
            ),
            Certificate(
                title: "Machine Learning Fundamentals",
                issuer: "Online Learning Institute",
                issueDate: date(year: 2026, month: 1, day: 22),
                credentialID: "MLF-2026-8821",
                verificationURL: "https://careerledger.example.com/certificates/ml-fundamentals",
                verificationStatus: .evidenceProvided
            )
        ]

        let demoSemesters = [
            Semester(semesterNumber: 1, sgpa: 8.2, subjects: [
                Subject(name: "Programming", grade: "A"),
                Subject(name: "Mathematics", grade: "A+"),
                Subject(name: "Physics", grade: "B+")
            ]),
            Semester(semesterNumber: 2, sgpa: 8.6, subjects: [
                Subject(name: "Data Structures", grade: "A+"),
                Subject(name: "Database Systems", grade: "A"),
                Subject(name: "English", grade: "A")
            ]),
            Semester(semesterNumber: 3, sgpa: 8.8, subjects: [
                Subject(name: "Operating Systems", grade: "A"),
                Subject(name: "Computer Networks", grade: "A"),
                Subject(name: "Software Engineering", grade: "A+")
            ]),
            Semester(semesterNumber: 4, sgpa: 9.0, subjects: [
                Subject(name: "Machine Learning", grade: "A+"),
                Subject(name: "Mobile App Development", grade: "A+"),
                Subject(name: "Design Thinking", grade: "A")
            ])
        ]

        modelContext.insert(student)
        demoAchievements.forEach(modelContext.insert)
        demoProjects.forEach(modelContext.insert)
        demoCertificates.forEach(modelContext.insert)
        demoSemesters.forEach(modelContext.insert)
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
