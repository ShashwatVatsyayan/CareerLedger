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

    static func seedIfNeeded(modelContext: ModelContext) {
        let existingStudents = (try? modelContext.fetch(FetchDescriptor<Student>())) ?? []
        let existingAchievements = (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
        let existingProjects = (try? modelContext.fetch(FetchDescriptor<Project>())) ?? []
        let existingCertificates = (try? modelContext.fetch(FetchDescriptor<Certificate>())) ?? []
        let existingSemesters = (try? modelContext.fetch(FetchDescriptor<Semester>())) ?? []

        if let existing = existingStudents.first {
            if existing.name == "Student" || existing.name.isEmpty {
                existing.name = "Shashwat Vatsyayan"
                existing.course = "B.E. Computer Science"
                existing.university = "Chandigarh University"
                existing.bio = "Computer Science student building practical AI, iOS, and web products with a focus on verified career evidence."
                existing.githubURL = "https://github.com/ShashwatVatsyayan/CareerLedger"
                existing.linkedinURL = "https://www.linkedin.com/"
                existing.portfolioURL = "https://careerledger.example.com/shashwat-vatsyayan"
                existing.skills = ["SwiftUI", "SwiftData", "Python", "Machine Learning", "Firebase", "Product Design"]
            }
        } else {
            let student = Student(
                name: "Shashwat Vatsyayan",
                course: "B.E. Computer Science",
                university: "Chandigarh University",
                email: "student@example.com",
                bio: "Computer Science student building practical AI, iOS, and web products with a focus on verified career evidence.",
                githubURL: "https://github.com/ShashwatVatsyayan/CareerLedger",
                linkedinURL: "https://www.linkedin.com/",
                universityURL: "https://www.cuchd.in/",
                instagramURL: "https://www.instagram.com/",
                portfolioURL: "https://careerledger.example.com/shashwat-vatsyayan",
                skills: ["SwiftUI", "SwiftData", "Python", "Machine Learning", "Firebase", "Product Design"]
            )
            modelContext.insert(student)
        }

        if existingAchievements.isEmpty {
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
            demoAchievements.forEach(modelContext.insert)
        }

        if existingProjects.isEmpty {
            let demoProjects = [
                Project(
                    name: "Aegis AI",
                    description: "AI-assisted media authenticity tool for detecting manipulated or deepfake content.",
                    technologies: "Python, Machine Learning, Flask",
                    githubURL: "https://github.com/ShashwatVatsyayan/CareerLedger",
                    demoURL: "https://careerledger.example.com/projects/aegis-ai",
                    verificationStatus: .evidenceProvided,
                    date: date(year: 2026, month: 3, day: 2)
                ),
                Project(
                    name: "uniVerse",
                    description: "Campus companion app concept for academic planning, events, and verified student profiles.",
                    technologies: "SwiftUI, SwiftData, CloudKit",
                    githubURL: "https://github.com/ShashwatVatsyayan",
                    demoURL: "https://careerledger.example.com/projects/universe",
                    verificationStatus: .sourceVerified,
                    date: date(year: 2026, month: 1, day: 16)
                )
            ]
            demoProjects.forEach(modelContext.insert)
        }

        if existingCertificates.isEmpty {
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
            demoCertificates.forEach(modelContext.insert)
        }

        if existingSemesters.isEmpty {
            let s1 = Semester(semesterNumber: 1, sgpa: 8.2)
            let s1Subjects = [
                Subject(name: "Programming", grade: "A"),
                Subject(name: "Mathematics", grade: "A+"),
                Subject(name: "Physics", grade: "B+")
            ]
            s1.subjects = s1Subjects
            modelContext.insert(s1)
            s1Subjects.forEach {
                $0.semester = s1
                modelContext.insert($0)
            }

            let s2 = Semester(semesterNumber: 2, sgpa: 8.6)
            let s2Subjects = [
                Subject(name: "Data Structures", grade: "A+"),
                Subject(name: "Database Systems", grade: "A"),
                Subject(name: "English", grade: "A")
            ]
            s2.subjects = s2Subjects
            modelContext.insert(s2)
            s2Subjects.forEach {
                $0.semester = s2
                modelContext.insert($0)
            }

            let s3 = Semester(semesterNumber: 3, sgpa: 8.8)
            let s3Subjects = [
                Subject(name: "Operating Systems", grade: "A"),
                Subject(name: "Computer Networks", grade: "A"),
                Subject(name: "Software Engineering", grade: "A+")
            ]
            s3.subjects = s3Subjects
            modelContext.insert(s3)
            s3Subjects.forEach {
                $0.semester = s3
                modelContext.insert($0)
            }

            let s4 = Semester(semesterNumber: 4, sgpa: 9.0)
            let s4Subjects = [
                Subject(name: "Machine Learning", grade: "A+"),
                Subject(name: "Mobile App Development", grade: "A+"),
                Subject(name: "Design Thinking", grade: "A")
            ]
            s4.subjects = s4Subjects
            modelContext.insert(s4)
            s4Subjects.forEach {
                $0.semester = s4
                modelContext.insert($0)
            }
        }

        do {
            try modelContext.save()
            print("Successfully saved seeded database records.")
        } catch {
            print("Failed to save seeded database records: \(error)")
        }
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
